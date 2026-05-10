import UIKit
import AVFoundation

// MARK: - Контроллер
class ClickerViewController: UIViewController {
    private let apiUrl = "https://jetong.ru/fuzz/api.php"
    private var timer: Timer?
    private let synthesizer = AVSpeechSynthesizer()
    private var xpcConnection: xpc_connection_t?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "XPC готов"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let xpcButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ОТПРАВИТЬ XPC", for: .normal)
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
        
        xpcButton.addTarget(self, action: #selector(sendXPC), for: .touchUpInside)
        
        setupXPC()
    }
    
    private func setupXPC() {
        xpcConnection = xpc_connection_create_mach_service("com.apple.mobileassetd", nil, 0)
        
        xpc_connection_set_event_handler(xpcConnection!) { [weak self] event in
            DispatchQueue.main.async {
                if event === XPC_ERROR_CONNECTION_INVALID {
                    self?.statusLabel.text = "XPC: соединение разорвано"
                    self?.speak("Ошибка соединения")
                } else if xpc_get_type(event) == XPC_TYPE_DICTIONARY {
                    // Ответ от демона
                    let desc = xpc_copy_description(event)
                    self?.statusLabel.text = "Ответ: \(String(cString: desc!))"
                    self?.speak("Получен ответ от демона")
                    free(desc)
                } else {
                    let desc = xpc_copy_description(event)
                    self?.statusLabel.text = "Событие: \(String(cString: desc!))"
                    free(desc)
                }
            }
        }
        
        xpc_connection_resume(xpcConnection!)
        statusLabel.text = "XPC: соединение установлено"
        speak("Соединение установлено")
    }
    
    @objc private func sendXPC() {
        guard let conn = xpcConnection else {
            statusLabel.text = "XPC: нет соединения"
            return
        }
        
        let message = xpc_dictionary_create(nil, nil, 0)
        xpc_dictionary_set_string(message, "action", "ping")
        xpc_dictionary_set_bool(message, "test", true)
        
        statusLabel.text = "Отправка XPC..."
        speak("Отправляю сообщение")
        
        xpc_connection_send_message_with_reply(conn, message, nil) { [weak self] reply in
            DispatchQueue.main.async {
                if let error = xpc_dictionary_get_value(reply, XPC_ERROR_KEY) {
                    self?.statusLabel.text = "Ошибка демона"
                    self?.speak("Демон вернул ошибку")
                } else {
                    let desc = xpc_copy_description(reply)
                    self?.statusLabel.text = "Успех: \(String(cString: desc!))"
                    self?.speak("Демон ответил")
                    free(desc)
                }
            }
        }
    }
    
    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.5
        synthcoder.speak(utterance)
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

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
