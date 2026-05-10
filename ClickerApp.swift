import UIKit
import AVFoundation

// MARK: - XPC Service Delegate (Слушатель)
class XPCServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Принимаем любое подключение
        newConnection.exportedInterface = NSXPCInterface(with: XPCServiceProtocol.self)
        newConnection.exportedObject = XPCService()
        newConnection.resume()
        return true
    }
}

// MARK: - Протокол XPC сервиса
@objc protocol XPCServiceProtocol {
    func executeCommand(_ command: String, withReply reply: @escaping (String) -> Void)
}

// MARK: - Реализация сервиса
class XPCService: NSObject, XPCServiceProtocol {
    func executeCommand(_ command: String, withReply reply: @escaping (String) -> Void) {
        // Здесь выполняем команду с правами нашего приложения
        let result = "Выполнена команда: \(command)"
        reply(result)
    }
}

// MARK: - Контроллер
class ClickerViewController: UIViewController {
    private let logURL = "https://jetong.ru/fuzz/log.php"
    private let synthesizer = AVSpeechSynthesizer()
    private var xpcListener: NSXPCListener?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "XPC Сервис готов"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let xpcButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ЗАПУСТИТЬ СЕРВИС", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        statusLabel.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 120)
        xpcButton.frame = CGRect(x: 50, y: view.bounds.height - 200, width: view.bounds.width - 100, height: 60)
        
        view.addSubview(statusLabel)
        view.addSubview(xpcButton)
        
        xpcButton.addTarget(self, action: #selector(toggleService), for: .touchUpInside)
        
        // Запускаем слушатель сразу
        startXPCListener()
    }
    
    private func sendLog(_ msg: String) {
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? msg
        guard let url = URL(string: "\(logURL)?msg=\(encoded)") else { return }
        URLSession.shared.dataTask(with: url).resume()
    }
    
    private func startXPCListener() {
        let serviceName = "com.jetong.clicker.xpc"
        xpcListener = NSXPCListener(machServiceName: serviceName)
        xpcListener?.delegate = XPCServiceDelegate()
        xpcListener?.resume()
        
        statusLabel.text = "Сервис запущен на \(serviceName)"
        sendLog("XPC: слушатель запущен на \(serviceName)")
        speak("Сервис запущен")
    }
    
    @objc private func toggleService() {
        if let listener = xpcListener {
            listener.suspend()
            xpcListener = nil
            statusLabel.text = "Сервис остановлен"
            sendLog("XPC: сервис остановлен")
            speak("Сервис остановлен")
        } else {
            startXPCListener()
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

// MARK: - AppDelegate
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

// MARK: - Точка входа
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
