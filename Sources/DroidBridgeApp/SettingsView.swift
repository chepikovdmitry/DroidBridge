import DroidBridgeCore
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Picker(L10n.text("Language"), selection: Binding(
                get: { L10n.current.language },
                set: { L10n.selectLanguage($0) }
            )) {
                Text(L10n.text("System Language")).tag("")
                Text(verbatim: "English").tag("en")
                Text(verbatim: "Русский").tag("ru")
                Text(verbatim: "Español").tag("es")
                Text(verbatim: "Français").tag("fr")
                Text(verbatim: "Deutsch").tag("de")
                Text(verbatim: "Português (Brasil)").tag("pt-BR")
                Text(verbatim: "日本語").tag("ja")
                Text(verbatim: "简体中文").tag("zh-Hans")
            }

            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
               let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                LabeledContent(L10n.text("Version"), value: "\(version) (\(build))")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}
