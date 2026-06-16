//
//  LocalizedStrings.swift
//  OwnFont
//

import Foundation

enum L {
    private static func s(_ key: String) -> String { LanguageManager.shared.string(key) }

    // MARK: - Tab Bar
    static var tabBarDecorate:        String { s("tabBar.decorate") }
    static var tabBarCharacterSet:    String { s("tabBar.characterSet") }
static var tabBarCharacterIcon:   String {
        LanguageManager.shared.effectiveLanguageCode == "ko" ? "character.ko" : "character"
    }

    // MARK: - Badge
    static var badgeNotStarted:  String { s("badge.notStarted") }
    static var badgeInProgress:  String { s("badge.inProgress") }
    static var badgeCompleted:   String { s("badge.completed") }

    // MARK: - Buttons
    static var buttonSave:    String { s("button.save") }
    static var buttonDone:    String { s("button.done") }
    static var buttonDelete:  String { s("button.delete") }
    static var buttonCancel:  String { s("button.cancel") }
    static var buttonConfirm: String { s("button.confirm") }

    // MARK: - Size Segment
    static var sizeSmall:  String { s("size.small") }
    static var sizeMedium: String { s("size.medium") }
    static var sizeLarge:  String { s("size.large") }

    // MARK: - Category
    static var categoryLowercaseLatin:  String { s("category.lowercaseLatin") }
    static var categoryUppercaseLatin:  String { s("category.uppercaseLatin") }
    static var categoryNumber:          String { s("category.number") }
    static var categorySymbol:          String { s("category.symbol") }
    static var categoryHangulChoseong:  String { s("category.hangulChoseong") }
    static var categoryHangulJungseong: String { s("category.hangulJungseong") }

    static func categorySubtitle(rangeLabel: String, completedCount: Int, totalCount: Int) -> String {
        LanguageManager.shared.string("category.subtitle", rangeLabel, completedCount, totalCount)
    }

    // MARK: - Character Set
    static var characterSetTitle:        String { s("characterSet.title") }
    static var characterSetSubtitle:     String { s("characterSet.subtitle") }
    static var characterSetEditorButton: String { s("characterSet.editorButton") }

    static func writingProgress(percent: Int) -> String {
        LanguageManager.shared.string("writing.progress", percent)
    }

    // MARK: - Text Editor
    static var textEditorTitle:       String { s("textEditor.title") }
    static var textEditorPlaceholder: String { s("textEditor.placeholder") }
    static var textEditorFontSize:    String { s("textEditor.fontSize") }

    // MARK: - Character Writing
    static var characterWritingTitle:          String { s("characterWriting.title") }
    static var characterWritingCompletedChars: String { s("characterWriting.completedChars") }
    static var characterWritingCurrentChar:    String { s("characterWriting.currentChar") }
    static var characterWritingNextChar:       String { s("characterWriting.nextChar") }

    // MARK: - Card Home
    static var cardHomeMemoTitle:     String { s("cardHome.memoTitle") }
    static var cardHomeMemoSubtitle:  String { s("cardHome.memoSubtitle") }
    static var cardHomePhotoSubtitle: String { s("cardHome.photoSubtitle") }

    // MARK: - Card Decorate
    static var cardDecorateTitle:           String { s("cardDecorate.title") }
    static var cardDecorateMainPlaceholder: String { s("cardDecorate.mainTextPlaceholder") }
    static var cardDecorateSubPlaceholder:  String { s("cardDecorate.subTextPlaceholder") }

    // MARK: - Photo Decorate
    static var photoDecorateTitle: String { s("photoDecorate.title") }

    // MARK: - Segment
    static var segmentText:  String { s("segment.text") }
    static var segmentColor: String { s("segment.color") }

    // MARK: - Color Section
    static var colorSectionBackground: String { s("colorSection.background") }
    static var colorSectionText:       String { s("colorSection.text") }

    // MARK: - Memo Card
    static var memoCardMainPlaceholder: String { s("memoCard.mainPlaceholder") }
    static var memoCardSubPlaceholder:  String { s("memoCard.subPlaceholder") }

    // MARK: - Instagram
    static var instagramStory:              String { s("instagram.story") }
    static var instagramShareAccessibility: String { s("instagram.shareAccessibility") }

    // MARK: - Alerts
    static var alertShareFailedTitle:   String { s("alert.shareFailed.title") }
    static var alertShareFailedMessage: String { s("alert.shareFailed.message") }
    static var alertSaveFailedTitle:    String { s("alert.saveFailed.title") }
    static var alertSaveFailedMessage:  String { s("alert.saveFailed.message") }

    static func alertClearAllTitle(_ categoryTitle: String) -> String {
        LanguageManager.shared.string("alert.clearAll.title", categoryTitle)
    }
    static func alertClearAllMessage(_ categoryTitle: String) -> String {
        LanguageManager.shared.string("alert.clearAll.message", categoryTitle)
    }

    // MARK: - Toast
    static var toastSaveFailed:    String { s("toast.saveFailed") }
    static var toastSaveCompleted: String { s("toast.saveCompleted") }

    // MARK: - Settings
    static var settingsTitle:    String { s("settings.title") }
    static var settingsLanguage: String { s("settings.language") }
}
