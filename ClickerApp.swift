import SwiftUI
import AppIntents
import UIKit
import UserNotifications

// ========== INTENT ==========
struct ReadRootIntent: AppIntent {
    static var title: LocalizedStringResource = "Прочитать корень системы"
    
    func perform() async throws -> some IntentResult {
        let fm = FileManager.default
        do {
            let items = try fm.contentsOfDirectory(atPath: "/")
            let output = items.joined(separator: "\n")
            
            // Буфер обмена
            UIPasteboard.general.string = output
            
            // Файл
            let logPath = "/var/mobile/root_list.txt"
            try output.write(toFile: logPath, atomically: true, encoding: .utf8)
            
            // Уведомление
            let notification = UNMutableNotificationContent()
            notification.title = "Готово"
            notification.body = "Список скопирован в буфер обмена"
            let request = UNNotificationRequest(identifier: "rootRead", content: notification, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
            
            return .result(value: "Скопировано в буфер обмена")
        } catch {
            let errorMsg = "Ошибка: \(error.localizedDescription)"
            UIPasteboard.general.string = errorMsg
            return .result(value: errorMsg)
        }
    }
}

// ========== REGISTRATION ==========
struct JailbreakShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReadRootIntent(),
            phrases: ["Прочитать корень системы"],
            shortTitle: "Чтение корня",
            systemImageName: "folder"
        )
    }
}

// ========== UI ==========
struct ContentView: View {
    @State private var status: String = "Нажмите кнопку или скажите Siri"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("📁 Root Reader")
                .font(.largeTitle)
            
            Text(status)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Прочитать корень") {
                Task {
                    let result = await ReadRootIntent().perform()
                    status = result.value as? String ?? "Готово (без текста)"
                }
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
}

// ========== APP ENTRY ==========
@main
struct ClickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}