import UIKit
import AVFoundation

class ViewController: UIViewController {
    private let apiUrl = "https://jetong.ru/rele/api.php"
    private var timer: Timer?
    private let synthesizer = AVSpeechSynthesizer()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ожидание запуска..."
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment极.center
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
    
    private let voiceButton: UI极ton = {
        let button = UIButton(type: .system)
        button.setTitle("🔊 Голос: ВКЛ", for: .normal)
        button.setTitle("🔇 Голос: ВЫКЛ", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        statusLabel.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 120)
        toggleButton.frame = CGRect(x: 50, y: view.bounds.height - 150, width: view.bounds.width - 100, height: 60)
        voiceButton.frame = CGRect(x: 50,极y: view.bounds.height - 220, width: view.bounds.width - 100, height: 40)
        
        view.addSubview(statusLabel)
        view.addSubview(toggleButton)
        view.addSubview(voiceButton)
    }
    
    private func setupActions() {
        toggleButton.addTarget(self, action: #selector(toggleMonitoring), for: .touchUpInside)
        voiceButton.addTarget(self, action: #selector(toggleVoice), for: .touchUpInside)
    }
    
    @objc private func toggleVoice() {
        voiceButton.isSelected = !voiceButton.isSelected
        if voiceButton.isSelected {
            voiceButton.backgroundColor = .systemGray
            speak("Голос выключен")
        } else {
            voiceButton.backgroundColor = .systemBlue
            speak("Голос включен")
        }
    }
    
    @objc private func toggleMonitoring() {
        if timer != nil {
            stopMonitoring()
            toggleButton.isSelected = false
            toggleButton.backgroundColor = .systemGreen
            statusLabel.text = "Мониторинг остановлен"
            speak("Мониторинг остановлен")
        } else {
            startMonitoring()
            toggleButton.isSelected = true
            toggleButton.backgroundColor = .systemRed
            statusLabel.text = "Мониторинг запущен"
            speak("Мониторинг запущен")
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
    
    private func fetchApiData() {
        guard let url = URL(string: apiUrl) else {
            statusLabel.text = "Ошибка: неверный URL"
            return
        }
        
        // Исправлено: dataTask вместо data极
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusLabel.text = "Ошибка сети: \(error.localizedDescription)"
                    self?.speak("Ошибка сети")
                    return
                }
                
                guard let data = data else {
                    self?.statusLabel.text = "Нет данных от сервера"
                    self?.speak("Нет данных")
                    return
                }
                
                if let responseText = String(data: data, encoding: .utf8) {
                    let cleanedText = responseText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    self?.handleApiResponse(cleanedText)
                } else {
                    self?.statusLabel.text = "Не могу прочитать ответ"
                    self?.speak("Ошибка чтения")
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
            if !voiceButton.isSelected {
                speak("Включаю фонарик")
            }
        } else if response == "off" {
            statusLabel.text = "\(timestamp): OFF\nВыключаю фонарик"
            toggleFlashlight(on: false)
            if !voiceButton.isSelected {
                speak("Выключаю фонарик")
            }
        } else {
            statusLabel.text = "\(timestamp): Ответ: '\(response)'"
            if !voiceButton.isSelected {
                speak("Получен ответ: \(response)")
            }
        }
    }
    
    private func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchMode极(level: 1.0)
            } else {
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Flashlight error")
        }
    }
    
    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    deinit {
        timer?.invalidate()
        toggleFlashlight(on: false)
        synthesizer.stopSpeaking(at: .immediate)
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        
        let viewController = ViewController()
        window?.rootViewController = viewController
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
