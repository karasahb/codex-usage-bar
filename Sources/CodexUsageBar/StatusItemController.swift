import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let store: UsageStore
    private let updateChecker: UpdateChecker
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables = Set<AnyCancellable>()

    init(store: UsageStore, updateChecker: UpdateChecker) {
        self.store = store
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

        append(label: "", window: snapshot?.fiveHour, to: title, base: base)
        var separatorAttributes = base
        separatorAttributes[.foregroundColor] = NSColor.secondaryLabelColor
        title.append(NSAttributedString(string: " | ", attributes: separatorAttributes))
        append(label: "", window: snapshot?.weekly, to: title, base: base)
        button.attributedTitle = title
        button.setAccessibilityLabel(accessibilityLabel(snapshot))
    }

    private func append(
        label: String,
        window: RateLimitWindow?,
        to title: NSMutableAttributedString,
        base: [NSAttributedString.Key: Any]
    ) {
        title.append(NSAttributedString(string: label, attributes: base))
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
        let five = snapshot.fiveHour?.remainingPercent.description ?? unknown
        let week = snapshot.weekly?.remainingPercent.description ?? unknown
        return L10n.format(
            "usage.accessibility",
            fallback: "Remaining Codex usage: 5-hour %@ percent, weekly %@ percent",
            five,
            week
        )
    }
}
