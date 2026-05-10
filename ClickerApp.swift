import UIKit
import AVFoundation

// MARK: - Контроллер
class ClickerViewController: UIViewController {
    private let logURL = "https://jetong.ru/fuzz/log.php"
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
    
    private func sendLog(_ msg: String) {
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? msg
        guard let url = URL(string: "\(logURL)?msg=\(encoded)") else { return }
        URLSession.shared.dataTask(with: url).resume()
    }
    
    private func setupXPC() {
        let serviceName = "com.apple.mobileassetd"
        xpcConnection = xpc_connection_create(serviceName, nil)
        
        sendLog("XPC: создаю соединение к \(serviceName)")
        
        xpc_connection_set_event_handler(xpcConnection!) { [weak self] event in
            DispatchQueue.main.async {
                if xpc_get_type(event) == XPC_TYPE_ERROR {
                    self?.statusLabel.text = "XPC: ошибка соединения"
                    self?.sendLog("XPC: ERROR - соединение разорвано")
                    self?.speak("Ошибка соединения")
                } else if xpc_get_type(event) == XPC_TYPE_DICTIONARY {
                    let desc = xpc_copy_description(event)
                    let msg = String(cString: desc)
                    self?.statusLabel.text = "Ответ: \(msg)"
                    self?.sendLog("XPC: ответ от демона: \(msg)")
                    self?.speak("Демон ответил")
                    free(desc)
                } else {
                    let desc = xpc_copy_description(event)
                    let msg = String(cString: desc)
                    self?.sendLog("XPC: событие: \(msg)")
                    free(desc)
                }
            }
        }
        
        xpc_connection_resume(xpcConnection!)
        statusLabel.text = "XPC: соединение установлено"
        sendLog("XPC: соединение установлено")
        speak("Соединение установлено")
    }
    
    @objc private func sendXPC() {
        guard let conn = xpcConnection else {
            statusLabel.text = "XPC: нет соединения"
            sendLog("XPC: нет соединения")
            return
        }
        
        let message = xpc_dictionary_create(nil, nil, 0)
        xpc_dictionary_set_string(message, "action", "ping")
        xpc_dictionary_set_bool(message, "test", true)
        
        statusLabel.text = "Отправка XPC..."
        sendLog("XPC: отправляю ping")
        speak("Отправляю сообщение")
        
        xpc_connection_send_message_with_reply(conn, message, nil) { [weak self] reply in
            DispatchQueue.main.async {
                if xpc_get_type(reply) == XPC_TYPE_ERROR {
                    self?.statusLabel.text = "Ошибка демона"
                    self?.sendLog("XPC: демон вернул ошибку")
                    self?.speak("Демон вернул ошибку")
                } else {
                    let desc = xpc_copy_description(reply)
                    let msg = String(cString: desc)
                    self?.statusLabel.text = "Успех: \(msg)"
                    self?.sendLog("XPC: успешный ответ: \(msg)")
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
