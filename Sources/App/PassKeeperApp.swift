import SwiftUI

@main
struct PassKeeperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var i18nService = I18nService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(i18nService)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("menu.newPassword".localized) {
                    NotificationCenter.default.post(name: .addNewPassword, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .appSettings) {
                Button("menu.lockVault".localized) {
                    appState.lock()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app appearance
        NSWindow.allowsAutomaticWindowTabbing = false

        // Apply saved appearance mode
        let appearanceKey = "app_appearance_mode"
        let savedMode = AppearanceMode(rawValue: UserDefaults.standard.integer(forKey: appearanceKey)) ?? .system
        applyAppearance(savedMode)
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Secure cleanup on termination
        AppState.shared.secureCleanup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension Notification.Name {
    static let addNewPassword = Notification.Name("addNewPassword")
}
