import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.string("onboarding.title", fallback: "Welcome to Codex Usage Bar"))
                        .font(.largeTitle.weight(.bold))
                    Text(
                        L10n.string(
                            "onboarding.subtitle",
                            fallback: "Your remaining Codex limits, always visible in the menu bar."
                        )
                    )
                    .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                OnboardingRow(
                    image: "menubar.rectangle",
                    title: L10n.string("onboarding.menu_title", fallback: "Menu bar"),
                    detail: L10n.string(
                        "onboarding.menu_body",
                        fallback: "The two percentages show your remaining 5-hour and weekly usage. Click them for reset times and details."
                    )
                )

                OnboardingRow(
                    image: "lock.shield",
                    title: L10n.string("onboarding.privacy_title", fallback: "Private by design"),
                    detail: L10n.string(
                        "onboarding.privacy_body",
                        fallback: "No API key, token, email address, or account identifier is stored. Authentication stays with your existing Codex installation."
                    )
                )

                connectionRow

                if !ApplicationLocation.isInApplicationsDirectory() {
                    OnboardingRow(
                        image: "folder.badge.questionmark",
                        title: L10n.string("onboarding.location_title", fallback: "Move to Applications"),
                        detail: L10n.string(
                            "onboarding.location_body",
                            fallback: "For reliable launch-at-login behavior, move Codex Usage Bar to the Applications folder before continuing."
                        ),
                        color: .orange
                    )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle(
                    L10n.string("onboarding.launch_at_login", fallback: "Launch Codex Usage Bar when I log in"),
                    isOn: Binding(
                        get: { launchAtLogin.state.isSelected },
                        set: { launchAtLogin.setEnabled($0) }
                    )
                )
                .disabled(launchAtLogin.state == .unavailable)

                if launchAtLogin.state == .requiresApproval {
                    Button(L10n.string("startup.open_login_items", fallback: "Open Login Items")) {
                        launchAtLogin.openSystemSettings()
                    }
                    .controlSize(.small)
                }
            }

            HStack {
                if store.errorMessage != nil {
                    Button(L10n.string("common.retry", fallback: "Try Again")) {
                        store.reconnect()
                    }
                }

                Spacer()

                Button(L10n.string("onboarding.start", fallback: "Start Using Codex Usage Bar")) {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 600)
        .onAppear { launchAtLogin.refresh() }
    }

    @ViewBuilder
    private var connectionRow: some View {
        if store.snapshot != nil {
            OnboardingRow(
                image: "checkmark.circle.fill",
                title: L10n.string("onboarding.connection_title", fallback: "Codex connection"),
                detail: L10n.string(
                    "onboarding.connection_ready",
                    fallback: "Connected. Usage information is ready."
                ),
                color: .green
            )
        } else if let error = store.errorMessage {
            OnboardingRow(
                image: "exclamationmark.triangle.fill",
                title: L10n.string("onboarding.connection_title", fallback: "Codex connection"),
                detail: error,
                color: .red
            )
        } else {
            OnboardingRow(
                image: "ellipsis.circle",
                title: L10n.string("onboarding.connection_title", fallback: "Codex connection"),
                detail: L10n.string(
                    "onboarding.connection_loading",
                    fallback: "Checking your local Codex connection…"
                ),
                color: .secondary
            )
        }
    }
}

private struct OnboardingRow: View {
    let image: String
    let title: String
    let detail: String
    var color: Color = .accentColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: image)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }
}
