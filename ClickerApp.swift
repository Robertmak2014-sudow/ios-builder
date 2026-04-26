import UIKit
import AVFoundation

class ViewController: UIViewController {
    private let apiUrl = "https://jetong.ru/rele/api.php"
    private var timer: Timer?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ожидание запуска..."
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▶️ СТАРТ", for: .normal)
        button.setTitle("⏹️ СТОП", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View did load")
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Явно задаем frame для всех элементов
        statusLabel.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 120)
        toggleButton.frame = CGRect(x: 50, y: view.bounds.height - 150, width: view.bounds.width - 100, height: 60)
        
        // Добавляем на view
        view.addSubview(statusLabel)
        view.addSubview(toggleButton)
        
        print("UI setup completed")
    }
    
    private func setupActions() {
        toggleButton.addTarget(self, action: #selector(toggleMonitoring), for: .touchUpInside)
        print("Actions setup completed")
    }
    
    @objc private func toggleMonitoring() {
        if timer != nil {
            stopMonitoring()
            toggleButton.isSelected = false
            toggleButton.backgroundColor = .systemGreen
            statusLabel.text = "Мониторинг остановлен"
        } else {
            startMonitoring()
            toggleButton.isSelected = true
            toggleButton.backgroundColor = .systemRed
            statusLabel.text = "Мониторинг запущен\nОпрос каждые 3 секунды"
        }
    }
    
    private func startMonitoring() {
        print("Starting monitoring")
        fetchApiData()
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchApiData()
        }
    }
    
    private func stopMonitoring() {
        print("Stopping monitoring")
        timer?.invalidate()
        timer = nil
        toggleFlashlight(on: false)
    }
    
    private func fetchApiData() {
        print("Fetching API data")
        
        guard let url = URL(string: apiUrl) else {
            statusLabel.text = "Ошибка: неверный URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
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
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        if response == "on" {
            statusLabel.text = "\(timestamp): ON\nВключаю фонарик"
            toggleFlashlight(on: true)
        } else if response == "off" {
            statusLabel.text = "\(timestamp): OFF\nВыключаю фонарик"
            toggleFlashlight(on: false)
        } else {
            statusLabel.text = "\(timestamp): Ответ: '\(response)'"
        }
    }
    
    private func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Flashlight not available")
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchModeOn(level: 1.0)
                print("Flashlight ON")
            } else {
                device.torchMode = .off
                print("Flashlight OFF")
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Flashlight error: \(error)")
        }
    }
    
    deinit {
        timer?.invalidate()
        toggleFlashlight(on: false)
    }
}

// AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("App launching")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        
        let viewController = ViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
}

// Главная функция
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
