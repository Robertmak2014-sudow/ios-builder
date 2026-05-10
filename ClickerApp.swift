import UIKit
import AVFoundation
import Darwin

// MARK: - Контроллер
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
        button.setTitle("ДАМП ПАМЯТИ", for: .normal)
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
    
    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
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
        statusLabel.text = "Поиск базы..."
        sendLog("Ищем базовый адрес MobileAsset...")
        speak("Ищу библиотеку")
        
        // Используем C-функции dyld из <mach-o/dyld.h>
        let numImages = _dyld_image_count()
        sendLog("Всего образов: \(numImages)")
        
        var found = false
        for i in 0..<numImages {
            let name = _dyld_get_image_name(i)
            if name != nil {
                let nameStr = String(cString: name!)
                if nameStr.contains("MobileAsset") {
                    let baseAddr = _dyld_get_image_vmaddr_slide(i)
                    let header = _dyld_get_image_header(i)
                    sendLog("Найден MobileAsset! Индекс: \(i)")
                    sendLog("Имя: \(nameStr)")
                    sendLog("VM Slide: \(String(format: "0x%llX", baseAddr))")
                    sendLog("Header: \(String(format: "0x%llX", UInt(bitPattern: header)))")
                    
                    // Читаем заголовок Mach-O
                    let dumpSize = 16384
                    let data = Data(bytes: header!, count: dumpSize)
                    let hex = data.map { String(format: "%02x", $0) }.joined()
                    
                    sendLog("MACHO_HEADER_START")
                    let chunkSize = 1000
                    var offset = 0
                    while offset < hex.count {
                        let end = min(offset + chunkSize, hex.count)
                        let startIndex = hex.index(hex.startIndex, offsetBy: offset)
                        let endIndex = hex.index(hex.startIndex, offsetBy: end)
                        let chunk = String(hex[startIndex..<endIndex])
                        sendLog("MACHO:\(chunk)")
                        offset = end
                    }
                    sendLog("MACHO_HEADER_END")
                    
                    statusLabel.text = "Дамп отправлен!"
                    speak("Дамп успешно отправлен")
                    found = true
                    break
                }
            }
        }
        
        if !found {
            sendLog("MobileAsset не найден в образах")
            statusLabel.text = "Не найден"
            speak("Ошибка")
        }
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
