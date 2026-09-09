import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController {
    init(
        store: UsageStore,
        launchAtLogin: LaunchAtLoginManager,
        onFinish: @escaping () -> Void
    ) {
        super.init(window: nil)

        let view = OnboardingView(
            store: store,
            launchAtLogin: launchAtLogin,
            onFinish: onFinish
        )
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Codex Usage Bar"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
