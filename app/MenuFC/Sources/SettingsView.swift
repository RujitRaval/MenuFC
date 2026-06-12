import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = LoginItem.isEnabled
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // Placeholder mark — final app icon art is a TODO.
                Image(systemName: "soccerball")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MenuFC").font(.title2).bold()
                    Text("Version \(appVersion)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    if !LoginItem.setEnabled(newValue) {
                        launchAtLogin = LoginItem.isEnabled // revert if the toggle failed
                    }
                }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Live football scores in your menu bar.")
                    .font(.callout)
                Button("Data provided by football-data.org") {
                    if let u = URL(string: "https://www.football-data.org") { openURL(u) }
                }
                .buttonStyle(.link)
            }

            Spacer()
            Text("© 2026 Rujit Raval").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 360, height: 280)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
