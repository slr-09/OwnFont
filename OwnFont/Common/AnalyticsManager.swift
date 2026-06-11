//
//  AnalyticsManager.swift
//  OwnFont
//

import FirebaseAnalytics

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
}
