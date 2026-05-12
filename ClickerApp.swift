import UIKit
import Darwin

// MAResolvedKIOResolvedClinkerAPP - Контроллер
class FuzzerViewController: UIViewController {
    private let logView = UITextView()
    private let serverURL = "https://jetong.ru/fuzz/log.php"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        logView.frame = view.bounds
        logView.backgroundColor = .black
        logView.textColor = .green
        logView.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        logView.isEditable = false
        view.addSubview(logView)

        DispatchQueue.global(qos: .background).async {
            self.startFuzzing()
        }
    }

    private func log(_ message: String) {
        DispatchQueue.main.async {
            self.logView.text += message + "\n"
        }
        if let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "\(serverURL)?msg=\(encoded)") {
            URLSession.shared.dataTask(with: url).resume()
        }
    }

    private func startFuzzing() {
        log("=== Запуск фаззера IOKit (динамическая загрузка) ===")
        while true {
            fuzzIOSurfaceDynamic()
            sleep(1)
        }
    }

    // MARK: - Динамическая загрузка IOKit функций
    private func fuzzIOSurfaceDynamic() {
        guard let iokit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
            log("❌ Не удалось загрузить IOKit.framework")
            return
        }

        typealias IOServiceGetMatchingServiceFunc = @convention(c) (mach_port_t, CFDictionary?) -> io_service_t
        guard let IOServiceGetMatchingServicePtr = dlsym(iokit, "IOServiceGetMatchingService") else {
            log("❌ Символ не найден")
            dlclose(iokit)
            return
        }
        let IOServiceGetMatchingService = unsafeBitCast(IOServiceGetMatchingServicePtr, to: IOServiceGetMatchingServiceFunc.self)

        var service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOSurface"))
        log("Открыт сервис, результат: \(service)")
        IOObjectRelease(service)
        dlclose(iokit)
    }
}

// MARK: - AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = FuzzerViewController()
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
