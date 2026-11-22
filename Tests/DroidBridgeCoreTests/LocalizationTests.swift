@testable import DroidBridgeCore
import Observation
import Testing

struct LocalizationTests {
    @Test(arguments: [
        ("en", "Transfer Queue"),
        ("ru", "Очередь передач"),
        ("es", "Cola de transferencias"),
        ("fr", "File de transfert"),
        ("de", "Übertragungswarteschlange"),
        ("pt-BR", "Fila de transferências"),
        ("ja", "転送キュー"),
        ("zh-Hans", "传输队列"),
    ])
    func explicitLanguageSelectsItsOwnCatalog(language: String, expected: String) {
        #expect(L10n.bundle(for: language).localizedString(forKey: "Transfer Queue", value: nil, table: nil) == expected)
    }

    @Test func invalidPreferencesUseSystemLanguage() {
        #expect(L10n.bundle(for: "unsupported").bundleURL == L10n.bundle(for: "").bundleURL)
    }

    @MainActor @Test func changingLanguageInvalidatesDisplayedText() async {
        let localization = L10n(language: "en")
        await confirmation("Existing views are notified of the language change") { changed in
            withObservationTracking {
                #expect(localization.template("Transfer Queue") == "Transfer Queue")
            } onChange: {
                changed()
            }
            localization.setLanguage("ru")
            #expect(localization.template("Transfer Queue") == "Очередь передач")
            #expect(localization.language == "ru")
        }
    }
}
