import AppKit
import SwiftUI

@main
struct CodexUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settings: appDelegate.settings,
                store: appDelegate.store,
                launchAtLogin: appDelegate.launchAtLogin,
                updateChecker: appDelegate.updateChecker,
                notificationManager: appDelegate.notificationManager,
                applicationInstaller: appDelegate.applicationInstaller
            )
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let launchAtLogin = LaunchAtLoginManager()
    let applicationInstaller = ApplicationInstaller()
    lazy var updateChecker = UpdateChecker(settings: settings)
    lazy var store = UsageStore(settings: settings)
    lazy var notificationManager = UsageNotificationManager(settings: settings, store: store)
    private var statusController: StatusItemController?
    private var onboardingController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        statusController = StatusItemController(
            store: store,
            settings: settings,
            updateChecker: updateChecker
        )
        store.start()
        updateChecker.start()
        notificationManager.start()

        if ProcessInfo.processInfo.environment[
            ApplicationInstaller.enableLaunchAtLoginEnvironmentKey
        ] == "1" {
            launchAtLogin.setEnabled(true)
        }

        if !settings.hasCompletedOnboarding {
            let controller = OnboardingWindowController(
                store: store,
                launchAtLogin: launchAtLogin
            ) { [weak self] in
                guard let self else { return }
                self.settings.hasCompletedOnboarding = true
                self.onboardingController?.close()
                self.onboardingController = nil
            }
            onboardingController = controller
            controller.present()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
        updateChecker.stop()
        notificationManager.stop()
    }
}
