//
//  LanguageManager.swift
//  OwnFont
//

import Foundation

final class LanguageManager {
    static let shared = LanguageManager()
    static let languageDidChange = Notification.Name("languageDidChange")

    enum Language: String, CaseIterable {
        case system  = "system"
        case korean  = "ko"
        case english = "en"

        var displayName: String {
            switch self {
            case .system:  return "System Default"
            case .korean:  return "한국어"
            case .english: return "English"
            }
        }
    }

    private let userDefaultsKey = "appLanguage"
    private var cachedBundle: Bundle?
    private var cachedCode: String?

    var current: Language {
        let raw = UserDefaults.standard.string(forKey: userDefaultsKey) ?? Language.system.rawValue
        return Language(rawValue: raw) ?? .system
    }

    var effectiveLanguageCode: String {
        switch current {
        case .system:  return Locale.current.language.languageCode?.identifier ?? "en"
        case .korean:  return "ko"
        case .english: return "en"
        }
    }

    func setLanguage(_ language: Language) {
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
        cachedBundle = nil
        cachedCode   = nil
        NotificationCenter.default.post(name: Self.languageDidChange, object: nil)
    }

    func bundle() -> Bundle {
        let code = effectiveLanguageCode
        if code == cachedCode, let b = cachedBundle { return b }
        let b = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap { Bundle(path: $0) } ?? .main
        cachedBundle = b
        cachedCode   = code
        return b
    }

    func string(_ key: String) -> String {
        bundle().localizedString(forKey: key, value: key, table: "Localizable")
    }

    func string(_ key: String, _ args: CVarArg...) -> String {
        String(format: string(key), arguments: args)
    }
}
