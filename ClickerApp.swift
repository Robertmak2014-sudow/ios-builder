import AppIntents
import Foundation

struct ReadRootIntent: AppIntent {
    static var title: LocalizedStringResource = "Прочитать корень системы"
    
    func perform() async throws -> some IntentResult {
        let fm = FileManager.default
        do {
            // Читаем содержимое корня
            let items = try fm.contentsOfDirectory(atPath: "/")
            let output = items.joined(separator: "\n")
            
            // Сохраняем в заметки через UIPasteboard (буфер обмена)
            UIPasteboard.general.string = output
            
            // Дополнительно: сохраняем в файл в /var/mobile/
            let logPath = "/var/mobile/root_list.txt"
            try output.write(toFile: logPath, atomically: true, encoding: .utf8)
            
            // Показываем уведомление
            let notification = UNMutableNotificationContent()
            notification.title = "Готово"
            notification.body = "Список скопирован в буфер обмена и сохранён в /var/mobile/root_list.txt"
            let request = UNNotificationRequest(identifier: "rootRead", content: notification, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            
            return .result(value: "Скопировано в буфер обмена")
        } catch {
            // Если ошибка — показываем её
            let errorMsg = "Ошибка: \(error.localizedDescription)"
            UIPasteboard.general.string = errorMsg
            
            let notification = UNMutableNotificationContent()
            notification.title = "Ошибка"
            notification.body = errorMsg
            let request = UNNotificationRequest(identifier: "rootReadError", content: notification, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            
            return .result(value: errorMsg)
        }
    }
}
