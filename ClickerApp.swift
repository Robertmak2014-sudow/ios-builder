import UIKit
import AVFoundation

class ViewController: UIViewController {
    private let apiUrl = "https://jetong.ru/rele/api.php"
    private var isFlashlightOn = false
    private var timer: Timer?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Запуск..."
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let flashlightStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Фонарик: выключен"
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton()
        button.setTitle("▶️ Запуск мониторинга", for: .normal)
        button.setTitle("⏹️ Остановка", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        checkFlashlightAvailability()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        statusLabel.frame = CGRect(x: 20, y: 150, width: view.bounds.width - 40, height: 80)
        flashlightStatusLabel.frame = CGRect(x: 20, y: 240, width: view.bounds.width - 40, height: 30)
        startButton.frame = CGRect(x: (view.bounds.width - 200) / 2, y: 290, width: 200, height: 50)
        activityIndicator.frame = CGRect(x: (view.bounds.width - 20) / 2, y: 350, width: 20, height: 20)
        
        view.addSubview(statusLabel)
        view.addSubview(flashlightStatusLabel)
        view.addSubview(startButton)
        view.addSubview(activityIndicator)
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(toggleMonitoring), for: .touchUpInside)
    }
    
    private func checkFlashlightAvailability() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            statusLabel.text = "Ошибка: нет доступа к камере"
            startButton.isEnabled = false
            return
        }
        
        if !device.hasTorch {
            statusLabel.text = "Ошибка: нет фонарика"
            startButton.isEnabled = false
            return
        }
        
        statusLabel.text = "Готов к работе\nAPI: \(apiUrl)"
    }
    
    @objc private func toggleMonitoring() {
        if timer != nil {
            stopMonitoring()
            startButton.isSelected = false
            startButton.backgroundColor = .systemGreen
        } else {
            startMonitoring()
            startButton.isSelected = true
            startButton.backgroundColor = .systemRed
        }
    }
    
    private func startMonitoring() {
        statusLabel.text = "Мониторинг запущен\nКаждые 3 секунды"
        
        // Сразу делаем первый запрос
        fetchApiData()
        
        // Запускаем таймер на каждые 3 секунды
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchApiData()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        statusLabel.text = "Мониторинг остановлен"
        activityIndicator.stopAnimating()
    }
    
    private func fetchApiData() {
        activityIndicator.startAnimating()
        
        guard let url = URL(string: apiUrl) else {
            statusLabel.text = "Ошибка: неверный URL"
            activityIndicator.stopAnimating()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                if let error = error {
                    self?.statusLabel.text = "Ошибка сети: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.statusLabel.text = "Нет данных от сервера"
                    return
                }
                
                if let responseText = String(data: data, encoding: .utf8) {
                    let cleanedText = responseText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    self?.handleApiResponse(cleanedText)
                } else {
                    self?.statusLabel.text = "Не могу прочитать ответ"
                }
            }
        }
        
        task.resume()
    }
    
    private func handleApiResponse(_ response: String) {
        let statusText: String
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        if response == "on" {
            statusText = "\(timestamp): ON - включаю фонарик"
            toggleFlashlight(on: true)
        } else if response == "off" {
            statusText = "\(timestamp): OFF - выключаю фонарик"
            toggleFlashlight(on: false)
        } else {
            statusText = "\(timestamp): Неизвестная команда: '\(response)'"
        }
        
        statusLabel.text = statusText
    }
    
    private func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            flashlightStatusLabel.text = "Фонарик: ошибка доступа"
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchModeOn(level: 1.0)
                flashlightStatusLabel.text = "Фонарик: ВКЛЮЧЕН 🔦"
                flashlightStatusLabel.textColor = .systemGreen
            } else {
                device.torchMode = .off
                flashlightStatusLabel.text = "Фонарик: выключен"
                flashlightStatusLabel.textColor = .white
            }
            
            device.unlockForConfiguration()
        } catch {
            flashlightStatusLabel.text = "Фонарик: ошибка управления"
            flashlightStatusLabel.textColor = .systemRed
        }
    }
    
    deinit {
        timer?.invalidate()
        // Выключаем фонарик при закрытии приложения
        toggleFlashlight(on: false)
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, 
                   didFinishLaunch极WithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
