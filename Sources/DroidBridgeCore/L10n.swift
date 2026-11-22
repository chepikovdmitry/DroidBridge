import Foundation
import Observation
import Synchronization

package final class L10n: Observable, Sendable {
    private static let languagePreferenceKey = "DroidBridgeLanguage"
    package static let current = L10n(
        language: UserDefaults.standard.string(forKey: languagePreferenceKey) ?? ""
    )

    private let registrar = ObservationRegistrar()
    private let selection: Mutex<(language: String, bundle: Bundle)>

    init(language: String) {
        selection = Mutex((language, Self.bundle(for: language)))
    }

    package var language: String {
        registrar.access(self, keyPath: \.language)
        return selection.withLock { $0.language }
    }

    @MainActor
    package static func selectLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: languagePreferenceKey)
        current.setLanguage(language)
    }

    @MainActor
    func setLanguage(_ language: String) {
        guard language != selection.withLock({ $0.language }) else { return }
        let bundle = Self.bundle(for: language)
        registrar.withMutation(of: self, keyPath: \.language) {
            selection.withLock { $0 = (language, bundle) }
        }
    }

    private static let resources: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("DroidBridge_DroidBridgeCore.bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return .module
    }()

    static func bundle(for language: String) -> Bundle {
        guard let localization = resources.localizations.first(where: {
            $0.caseInsensitiveCompare(language) == .orderedSame
        }), let url = resources.url(forResource: localization, withExtension: "lproj"),
            let bundle = Bundle(url: url) else {
            return resources
        }
        return bundle
    }

    func template(_ key: String) -> String {
        registrar.access(self, keyPath: \.language)
        let bundle = selection.withLock { $0.bundle }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    package static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let template = current.template(key)
        return arguments.isEmpty
            ? template
            : String(format: template, locale: .current, arguments: arguments)
    }
}
