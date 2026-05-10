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
    statusLabel.text = "Дамп символов..."
    sendLog("Дамп символов MobileAsset...")
    speak("Ищу функции")
    
    // Получаем базовый адрес загруженного фреймворка
    let path = "/System/Library/PrivateFrameworks/MobileAsset.framework/MobileAsset"
    let handle = dlopen(path, RTLD_LAZY)
    
    if handle != nil {
        // Используем функцию для перечисления символов
        // dyld API не даёт прямой список, но мы можем попробовать известные имена
        let knownFunctions = [
            "MAAsset_Init",
            "MAStartup",
            "MAInitialize",
            "MASendUpdate",
            "MAProcessAsset",
            "MACheckForUpdate",
            "MAXPC_connect",
            "MAHandleMessage",
            "_MobileAssetInit",
            "_MobileAssetStartup",
            "AssetInit",
            "AssetStartup"
        ]
        
        for funcName in knownFunctions {
            let sym = dlsym(handle, funcName)
            if sym != nil {
                sendLog("Найден символ: \(funcName)")
            }
        }
        
        // Альтернативный способ: ищем через RTLD_DEFAULT
        let altFunctions = [
            "ASAssetCreate",
            "ASAssetCopy",
            "MAAssetCopy",
            "MobileAssetCopy"
        ]
        
        for funcName in altFunctions {
            let sym = dlsym(dlopen(nil, RTLD_LAZY), funcName)
            if sym != nil {
                sendLog("Найден (DEFAULT): \(funcName)")
            }
        }
        
        statusLabel.text = "Дамп отправлен в логи"
        sendLog("Дамп завершён")
    } else {
        let err = String(cString: dlerror())
        sendLog("Ошибка handle: \(err)")
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
