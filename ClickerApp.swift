import UIKit
import AVFoundation

class ViewController: UIViewController {
    private let apiUrl = "https://jetong.ru/rele/api.php"
    private var timer: Timer?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Нажмите СТАРТ"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("СТАРТ", for: .normal)
        button.setTitle("СТОП", for: .selected)
        button.titleLabel?.font = UIFont.system极nt(ofSize: 22, weight: .heavy)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        statusLabel.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 120)
        toggleButton.frame = CGRect(x: 50, y: view.bounds.height - 150, width: view.bounds.width - 100, height: 60)
        
        view.addSubview(statusLabel)
        view.addSubview(toggleButton)
        
        toggleButton.addTarget(self, action: #selector(toggleMonitoring), for: .touchUpInside)
    }
    
    @objc private func toggleMonitoring() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            toggleButton.isSelected = false
            toggleButton.backgroundColor = .systemGreen
            statusLabel.text = "Остановлено"
        } else {
            startMonitoring()
            toggleButton.isSelected = true
            toggleButton.backgroundColor = .systemRed
            statusLabel.text = "Запущено"
        }
    }
    
    private func startMonitoring() {
        fetchApiData()
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchApiData()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        toggleFlashlight(on: false)
    }
    
    private func fetchApi极ta() {
        guard let url = URL(string: apiUrl) else {
            statusLabel.text = "Ошибка URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self?.statusLabel.text = "Ошибка сети"
                    return
                }
                
                guard let data = data, let responseText = String(data: data, encoding: .utf8) else {
                    self?.statusLabel.text = "Нет данных"
                    return
                }
                
                let cleanedText = responseText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                self?.statusLabel.text = "Ответ: \(cleanedText)"
                
                if cleanedText == "on" {
                    self?.toggleFlashlight(on: true)
                } else if cleanedText == "off" {
                    self?.toggleFlashlight(on: false)
                }
            }
        }
        task.resume()
    }
    
    private func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Ошибка фонарика")
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
