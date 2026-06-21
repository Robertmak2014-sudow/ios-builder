import SwiftUI
import AppIntents

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
            try output.write(toFile: "/var/mobile/root_list.txt", atomically: true, encoding: .utf8)
            
            return .result(value: "Скопировано в буфер обмена")
        } catch {
            return .result(value: "Ошибка: \(error.localizedDescription)")
        }
    }
}

// ========== REGISTRATION ==========
struct JailbreakShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReadRootIntent(),
            phrases: ["Прочитать корень системы"]
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
                    do {
                        let result = try await ReadRootIntent().perform()
                        status = result.value as? String ?? "Готово"
                    } catch {
                        status = "Ошибка: \(error.localizedDescription)"
                    }
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