import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Codex Usage Bar")
                        .font(.title2.weight(.semibold))
                    Text("Bağlantı ve yenileme ayarları")
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("Codex bağlantısı") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Otomatik algıla", text: $settings.codexExecutablePath)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Seç…", action: chooseCodexExecutable)
                        Button("Otomatik bul") {
                            settings.useAutomaticCodexLocation()
                        }
                        .disabled(settings.normalizedCodexExecutablePath == nil)
                        Spacer()
                    }

                    Text(effectivePathText)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.top, 4)
            }

            GroupBox("Yenileme") {
                Picker("Kontrol sıklığı", selection: $settings.refreshInterval) {
                    ForEach(AppSettings.allowedRefreshIntervals, id: \.self) { seconds in
                        Text("\(Int(seconds)) saniye").tag(seconds)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)
            }

            GroupBox("Gizlilik") {
                Label {
                    Text("Uygulama token, API anahtarı, e-posta veya hesap kimliği kaydetmez. Yalnızca Codex yolu ve yenileme aralığı bu Mac'te saklanır.")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                }
                .padding(.top, 4)
            }

            HStack {
                if let message = store.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button("Bağlantıyı yenile") {
                    store.reconnect()
                }
            }
        }
        .padding(22)
        .frame(width: 520)
    }

    private var effectivePathText: String {
        if let customPath = settings.normalizedCodexExecutablePath {
            if let resolved = CodexAppServerClient.resolveConfiguredExecutable(customPath) {
                return "Kullanılan yol: \(resolved.path)"
            }
            return "Seçilen yol geçerli bir Codex uygulaması veya çalıştırılabilir dosya değil."
        }
        if let detected = CodexAppServerClient.autoDetectedExecutable() {
            return "Otomatik bulunan: \(detected.path)"
        }
        return "Codex çalıştırılabilir dosyası henüz bulunamadı."
    }

    private func chooseCodexExecutable() {
        let panel = NSOpenPanel()
        panel.title = "ChatGPT/Codex uygulamasını veya codex dosyasını seçin"
        panel.prompt = "Seç"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            settings.codexExecutablePath = url.path
        }
    }
}
