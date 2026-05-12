import UIKit
import IOKit
import Darwin

// MARK: - Главный контроллер-фаззер
class FuzzerViewController: UIViewController {
    private let logView = UITextView()
    private let serverURL = "https://jetong.ru/fuzz/log.php"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Настройка тёмного интерфейса
        view.backgroundColor = .black
        logView.frame = view.bounds
        logView.backgroundColor = .black
        logView.textColor = .green
        logView.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        logView.isEditable = false
        view.addSubview(logView)

        // Запускаем фаззинг в фоновом потоке
        DispatchQueue.global(qos: .background).async {
            self.startFuzzing()
        }
    }

    private func log(_ message: String) {
        DispatchQueue.main.async {
            self.logView.text += message + "\n"
        }
        // Отправка на сервер
        if let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "\(serverURL)?msg=\(encoded)") {
            URLSession.shared.dataTask(with: url).resume()
        }
    }

    private func startFuzzing() {
        log("=== Запуск фаззера IOKit ===")
        log("Поиск уязвимостей типа гонки (race condition)...")

        // Бесконечный цикл фаззинга (можно остановить кнопкой)
        while true {
            fuzzIOSurface()
            fuzzIOKitServices()
            sleep(1) // Небольшая пауза между циклами
        }
    }

    // MARK: - Фаззинг IOSurface
    private func fuzzIOSurface() {
        // Открываем сервис IOSurface (часто уязвим)
        var service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOSurface"))

        if service == 0 {
            log("❌ IOSurface сервис не найден")
            return
        }

        var connect: io_connect_t = 0
        let kr = IOServiceOpen(service, mach_task_self_, 0, &connect)

        if kr != KERN_SUCCESS {
            log("❌ Не удалось открыть IOSurface (ошибка: \(kr))")
            IOObjectRelease(service)
            return
        }

        log("✅ IOSurface сервис открыт (connect = \(connect))")

        // Пробуем разные системные вызовы с неожиданными параметрами
        fuzzIOConnectCallMethod(connect, selector: 0)
        fuzzIOConnectCallMethod(connect, selector: 1)
        fuzzIOConnectCallMethod(connect, selector: 5)
        fuzzIOConnectCallMethod(connect, selector: 10)

        // Закрываем соединение
        IOServiceClose(connect)
        IOObjectRelease(service)
    }

    // MARK: - Фаззинг других IOKit сервисов
    private func fuzzIOKitServices() {
        // Список сервисов, которые часто уязвимы
        let serviceNames = [
            "IOUserClient",
            "IOHDIXController",
            "IOUSBInterface",
            "IOBluetoothSerialClient",
            "AppleMobileFileIntegrity"
        ]

        for name in serviceNames {
            var iterator: io_iterator_t = 0
            let kr = IOServiceGetMatchingServices(
                kIOMasterPortDefault,
                IOServiceMatching(name),
                &iterator
            )

            if kr != KERN_SUCCESS {
                continue
            }

            var service = IOIteratorNext(iterator)
            while service != 0 {
                var connect: io_connect_t = 0
                let openKr = IOServiceOpen(service, mach_task_self_, 0, &connect)

                if openKr == KERN_SUCCESS {
                    log("✅ Открыт сервис \(name) (connect = \(connect))")

                    // Фаззим разные селекторы
                    for selector in 0...20 {
                        fuzzIOConnectCallMethod(connect, selector: selector)
                    }

                    IOServiceClose(connect)
                }

                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            IOObjectRelease(iterator)
        }
    }

    // MARK: - Фаззинг конкретного системного вызова
    private func fuzzIOConnectCallMethod(_ connect: io_connect_t, selector: Int) {
        // Готовим случайные данные для фаззинга
        let inputSize = Int.random(in: 0...4096)
        let inputData = malloc(inputSize)!
        memset(inputData, 0x41, inputSize) // Заполняем 'A'

        let outputSize = Int.random(in: 0...4096)
        let outputData = malloc(outputSize)!
        var outputCount = outputSize

        let kr = IOConnectCallMethod(
            connect,
            UInt32(selector),
            nil, 0,
            inputData, inputSize,
            outputData, &outputCount,
            nil, nil
        )

        if kr != KERN_SUCCESS && kr != 0xe00002c2 { // 0xe00002c2 = "unsupported method"
            log("⚠️ IOConnectCallMethod селектор \(selector) вернул ошибку \(kr) (0x\(String(kr, radix: 16)))")
        } else if kr == KERN_SUCCESS {
            log("✅ Селектор \(selector) успешно выполнен (размер ответа: \(outputCount))")
        }

        free(inputData)
        free(outputData)
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

// MARK: - Точка входа
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
