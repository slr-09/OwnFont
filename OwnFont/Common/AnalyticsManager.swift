//
//  AnalyticsManager.swift
//  OwnFont
//

import FirebaseAnalytics
import FirebaseCrashlytics

enum AnalyticsEvent {
    enum DecorateSource: String {
        case memo, photo
    }

    case decorateMemoOpened
    case decoratePhotoOpened
    case decorateBackgroundChanged
    case decorateTextColorChanged
    case decorateTextStickerAdded
    case decorateSaveImage(source: DecorateSource)
    case instagramShareTapped(source: DecorateSource)

    fileprivate var name: String {
        switch self {
        case .decorateMemoOpened:      return "decorate_memo_opened"
        case .decoratePhotoOpened:     return "decorate_photo_opened"
        case .decorateBackgroundChanged: return "decorate_background_changed"
        case .decorateTextColorChanged:  return "decorate_text_color_changed"
        case .decorateTextStickerAdded:  return "decorate_text_sticker_added"
        case .decorateSaveImage:       return "decorate_save_image"
        case .instagramShareTapped:    return "instagram_share_tapped"
        }
    }

    fileprivate var parameters: [String: Any]? {
        switch self {
        case .decorateSaveImage(let source):
            return ["source": source.rawValue]
        case .instagramShareTapped(let source):
            return ["source": source.rawValue]
        default:
            return nil
        }
    }
}

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setCrashContext(screen: String, category: CharacterCategory? = nil) {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(screen, forKey: "screen")
        if let category {
            crashlytics.setCustomValue(category.debugName, forKey: "character_category")
        }
    }

    func setWritingCrashContext(
        screen: String,
        category: CharacterCategory,
        index: Int?,
        character: String?,
        action: String,
        strokeCount: Int? = nil
    ) {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(screen, forKey: "screen")
        crashlytics.setCustomValue(category.debugName, forKey: "character_category")
        crashlytics.setCustomValue(index ?? -1, forKey: "character_index")
        crashlytics.setCustomValue(character ?? "", forKey: "character")
        crashlytics.setCustomValue(action, forKey: "last_action")
        if let strokeCount {
            crashlytics.setCustomValue(strokeCount, forKey: "stroke_count")
        }
        crashlytics.log("[\(screen)] \(action) category=\(category.debugName) index=\(index ?? -1) character=\(character ?? "")")
    }
}
