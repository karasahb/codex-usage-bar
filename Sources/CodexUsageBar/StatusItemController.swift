import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let store: UsageStore
    private let settings: AppSettings
    private let updateChecker: UpdateChecker
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables = Set<AnyCancellable>()

    init(store: UsageStore, settings: AppSettings, updateChecker: UpdateChecker) {
        self.store = store
        self.settings = settings
        self.updateChecker = updateChecker
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 320, height: 360)
        popover.contentViewController = NSHostingController(
            rootView: UsagePopoverView(store: store, updateChecker: updateChecker)
        )

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = L10n.string("usage.tooltip", fallback: "Remaining Codex usage")
        }

        store.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in self?.updateTitle(snapshot) }
            .store(in: &cancellables)

        settings.$menuBarDisplayMode
            .combineLatest(settings.$weeklyFirst)
            .dropFirst()
            .sink { [weak self] _ in self?.updateTitle(store.snapshot) }
            .store(in: &cancellables)

        updateTitle(nil)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            store.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func updateTitle(_ snapshot: UsageDisplaySnapshot?) {
        guard let button = statusItem.button else { return }
        let title = NSMutableAttributedString()
        let base: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        ]

        let windows: [RateLimitWindow?]
        switch settings.menuBarDisplayMode {
        case .fiveHour:
            windows = [snapshot?.fiveHour]
        case .weekly:
            windows = [snapshot?.weekly]
        case .both:
            windows = settings.weeklyFirst
                ? [snapshot?.weekly, snapshot?.fiveHour]
                : [snapshot?.fiveHour, snapshot?.weekly]
        }

        for (index, window) in windows.enumerated() {
            if index > 0 {
                var separatorAttributes = base
                separatorAttributes[.foregroundColor] = NSColor.secondaryLabelColor
                title.append(NSAttributedString(string: " | ", attributes: separatorAttributes))
            }
            append(window: window, to: title, base: base)
        }
        button.attributedTitle = title
        button.setAccessibilityLabel(accessibilityLabel(snapshot))
    }

    private func append(
        window: RateLimitWindow?,
        to title: NSMutableAttributedString,
        base: [NSAttributedString.Key: Any]
    ) {
        guard let window else {
            var attributes = base
            attributes[.foregroundColor] = NSColor.secondaryLabelColor
            title.append(NSAttributedString(string: "--%", attributes: attributes))
            return
        }

        var attributes = base
        attributes[.foregroundColor] = UsageBand(remainingPercent: window.remainingPercent).color
        title.append(NSAttributedString(string: "\(window.remainingPercent)%", attributes: attributes))
    }

    private func accessibilityLabel(_ snapshot: UsageDisplaySnapshot?) -> String {
        guard let snapshot else {
            return L10n.string(
                "usage.accessibility_loading",
                fallback: "Loading Codex usage information"
            )
        }
        let unknown = L10n.string("usage.unknown", fallback: "unknown")
        let five = L10n.format(
            "usage.accessibility_five_hour",
            fallback: "5-hour %@ percent",
            snapshot.fiveHour?.remainingPercent.description ?? unknown
        )
        let week = L10n.format(
            "usage.accessibility_weekly",
            fallback: "weekly %@ percent",
            snapshot.weekly?.remainingPercent.description ?? unknown
        )
        let values: [String]
        switch settings.menuBarDisplayMode {
        case .fiveHour: values = [five]
        case .weekly: values = [week]
        case .both: values = settings.weeklyFirst ? [week, five] : [five, week]
        }
        return L10n.format(
            "usage.accessibility_custom",
            fallback: "Remaining Codex usage: %@",
            values.joined(separator: ", ")
        )
    }
}
