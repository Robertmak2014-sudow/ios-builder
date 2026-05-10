import UIKit
import AVFoundation

class ClickerViewController: UIViewController {
    private let logURL = "https://jetong.ru/fuzz/log.php"
    private let synthesizer = AVSpeechSynthesizer()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Готов к загрузке"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ЗАГРУЗИТЬ MOBILEASSET", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let callButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ВЫЗВАТЬ ФУНКЦИЮ", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        statusLabel.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 100)
        loadButton.frame = CGRect(x: 50, y: 250, width: view.bounds.width - 100, height: 50)
        callButton.frame = CGRect(x: 50, y: 320, width: view.bounds.width - 100, height: 50)
        
        view.addSubview(statusLabel)
        view.addSubview(loadButton)
        view.addSubview(callButton)
        
        loadButton.addTarget(self, action: #selector(loadMobileAsset), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(callFunction), for: .touchUpInside)
    }
    
    private func sendLog(_ msg: String) {
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? msg
        guard let url = URL(string: "\(logURL)?msg=\(encoded)") else { return }
        URLSession.shared.dataTask(with: url).resume()
    }
    
    @objc private func loadMobileAsset() {
        statusLabel.text = "Загружаю MobileAsset..."
        sendLog("Пытаюсь загрузить MobileAsset.framework")
        speak("Загружаю фреймворк")
        
        let path = "/System/Library/PrivateFrameworks/MobileAsset.framework/MobileAsset"
        let handle = dlopen(path, RTLD_LAZY)
        
        if handle != nil {
            statusLabel.text = "MobileAsset загружен!"
            sendLog("Успех: MobileAsset загружен")
            speak("Фреймворк загружен")
        } else {
            let err = String(cString: dlerror())
            statusLabel.text = "Ошибка загрузки"
            sendLog("Ошибка: \(err)")
            speak("Ошибка загрузки")
        }
    }
    
    @objc private func callFunction() {
        statusLabel.text = "Вызываю функцию..."
        sendLog("Пытаюсь вызвать MAAsset_Init")
        speak("Вызываю функцию")
        
        // Пробуем найти символ
        let sym = dlsym(dlopen(nil, RTLD_LAZY), "MAAsset_Init")
        if sym != nil {
            statusLabel.text = "Функция найдена!"
            sendLog("Успех: символ MAAsset_Init найден")
            speak("Функция найдена")
        } else {
            let err = String(cString: dlerror())
            statusLabel.text = "Символ не найден"
            sendLog("Ошибка поиска символа: \(err)")
            speak("Символ не найден")
        }
    }
    
    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = ClickerViewController()
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
