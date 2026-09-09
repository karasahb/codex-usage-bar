import AppKit
import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var updateChecker: UpdateChecker
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let snapshot = store.snapshot {
                UsageWindowCard(
                    title: L10n.string("usage.five_hour", fallback: "5-hour"),
                    systemImage: "clock",
                    window: snapshot.fiveHour
                )
                UsageWindowCard(
                    title: L10n.string("usage.weekly", fallback: "Weekly"),
                    systemImage: "calendar",
                    window: snapshot.weekly
                )

                if snapshot.resetCreditCount > 0 {
                    Label(resetCreditText(snapshot.resetCreditCount), systemImage: "arrow.clockwise.circle")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            } else if store.errorMessage == nil {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(L10n.string("usage.loading", fallback: "Loading usage…"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            }

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if case .available(let version, let url) = updateChecker.state {
                HStack(spacing: 8) {
                    Label(
                        L10n.format("update.banner", fallback: "Version %@ is available", version),
                        systemImage: "arrow.down.circle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    Spacer()
                    Link(L10n.string("common.download", fallback: "Download"), destination: url)
                        .font(.caption.weight(.semibold))
                }
            }

            Divider()

            HStack {
                Text(ResetDateFormatter.updateTime(store.snapshot?.updatedAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    store.refresh()
                } label: {
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .help(L10n.string("refresh.now", fallback: "Refresh now"))

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help(L10n.string("common.settings", fallback: "Settings"))

                Button(L10n.string("common.quit", fallback: "Quit")) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.string("usage.title", fallback: "Codex Usage"))
                    .font(.headline)
                Text(planName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(store.errorMessage == nil ? Color.green : Color.red)
                .frame(width: 7, height: 7)
                .help(
                    store.errorMessage == nil
                        ? L10n.string("usage.connected", fallback: "Connected")
                        : L10n.string("usage.connection_problem", fallback: "Connection problem")
                )
        }
    }

    private var planName: String {
        guard let plan = store.snapshot?.planType else {
            return L10n.string("usage.connecting", fallback: "Connecting…")
        }
        switch plan {
        case "plus": return "ChatGPT Plus"
        case "pro": return "ChatGPT Pro"
        case "free": return "ChatGPT Free"
        case "business", "team": return "ChatGPT Business"
        case "enterprise": return "ChatGPT Enterprise"
        case "edu", "edu_plus", "edu_pro": return "ChatGPT Edu"
        default: return plan.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func resetCreditText(_ count: Int) -> String {
        if count == 1 {
            return L10n.string("usage.reset_credit_one", fallback: "1 reset credit available")
        }
        return L10n.format(
            "usage.reset_credit_many",
            fallback: "%d reset credits available",
            count
        )
    }
}

private struct UsageWindowCard: View {
    let title: String
    let systemImage: String
    let window: RateLimitWindow?

    var body: some View {
        let remaining = window?.remainingPercent ?? 0
        let color = Color(nsColor: UsageBand(remainingPercent: remaining).color)

        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(window == nil ? "—" : "%\(remaining)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(window == nil ? Color.secondary : color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.primary.opacity(0.09))
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(remaining) / 100)
                }
            }
            .frame(height: 7)

            HStack {
                Text(L10n.string("usage.remaining", fallback: "Remaining usage"))
                Spacer()
                Text(
                    L10n.format(
                        "usage.resets",
                        fallback: "Resets: %@",
                        ResetDateFormatter.string(for: window?.resetDate)
                    )
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }
}
