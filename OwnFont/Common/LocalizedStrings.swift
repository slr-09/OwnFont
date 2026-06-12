//
//  L.swift
//  OwnFont
//

import Foundation

enum L {
    // MARK: - Tab Bar
    static let tabBarDecorate        = String(localized: "tabBar.decorate")
    static let tabBarCharacterSet    = String(localized: "tabBar.characterSet")
    static let tabBarCharacterIcon   = Locale.current.language.languageCode?.identifier == "ko" ? "character.ko" : "character"

    // MARK: - Badge
    static let badgeNotStarted       = String(localized: "badge.notStarted")
    static let badgeInProgress       = String(localized: "badge.inProgress")
    static let badgeCompleted        = String(localized: "badge.completed")

    // MARK: - Buttons
    static let buttonSave            = String(localized: "button.save")
    static let buttonDone            = String(localized: "button.done")
    static let buttonDelete          = String(localized: "button.delete")
    static let buttonCancel          = String(localized: "button.cancel")
    static let buttonConfirm         = String(localized: "button.confirm")

    // MARK: - Size Segment
    static let sizeSmall             = String(localized: "size.small")
    static let sizeMedium            = String(localized: "size.medium")
    static let sizeLarge             = String(localized: "size.large")

    // MARK: - Category
    static let categoryLowercaseLatin = String(localized: "category.lowercaseLatin")
    static let categoryUppercaseLatin = String(localized: "category.uppercaseLatin")
    static let categoryNumber         = String(localized: "category.number")
    static let categorySymbol         = String(localized: "category.symbol")

    static func categorySubtitle(rangeLabel: String, completedCount: Int, totalCount: Int) -> String {
        String(format: String(localized: "category.subtitle"), rangeLabel, completedCount, totalCount)
    }

    // MARK: - Character Set
    static let characterSetTitle        = String(localized: "characterSet.title")
    static let characterSetSubtitle     = String(localized: "characterSet.subtitle")
    static let characterSetEditorButton = String(localized: "characterSet.editorButton")

    // MARK: - Text Editor
    static let textEditorTitle       = String(localized: "textEditor.title")
    static let textEditorPlaceholder = String(localized: "textEditor.placeholder")
    static let textEditorFontSize    = String(localized: "textEditor.fontSize")

    // MARK: - Character Writing
    static let characterWritingTitle          = String(localized: "characterWriting.title")
    static let characterWritingCompletedChars = String(localized: "characterWriting.completedChars")
    static let characterWritingCurrentChar    = String(localized: "characterWriting.currentChar")
    static let characterWritingNextChar       = String(localized: "characterWriting.nextChar")

    // MARK: - Card Home
    static let cardHomeMemoTitle     = String(localized: "cardHome.memoTitle")
    static let cardHomeMemoSubtitle  = String(localized: "cardHome.memoSubtitle")
    static let cardHomePhotoSubtitle = String(localized: "cardHome.photoSubtitle")

    // MARK: - Card Decorate
    static let cardDecorateTitle            = String(localized: "cardDecorate.title")
    static let cardDecorateMainPlaceholder  = String(localized: "cardDecorate.mainTextPlaceholder")
    static let cardDecorateSubPlaceholder   = String(localized: "cardDecorate.subTextPlaceholder")

    // MARK: - Photo Decorate
    static let photoDecorateTitle    = String(localized: "photoDecorate.title")

    // MARK: - Segment
    static let segmentText           = String(localized: "segment.text")
    static let segmentColor          = String(localized: "segment.color")

    // MARK: - Color Section
    static let colorSectionBackground = String(localized: "colorSection.background")
    static let colorSectionText       = String(localized: "colorSection.text")

    // MARK: - Memo Card
    static let memoCardMainPlaceholder = String(localized: "memoCard.mainPlaceholder")
    static let memoCardSubPlaceholder  = String(localized: "memoCard.subPlaceholder")

    // MARK: - Instagram
    static let instagramStory             = String(localized: "instagram.story")
    static let instagramShareAccessibility = String(localized: "instagram.shareAccessibility")

    // MARK: - Alerts
    static let alertShareFailedTitle   = String(localized: "alert.shareFailed.title")
    static let alertShareFailedMessage = String(localized: "alert.shareFailed.message")
    static let alertSaveFailedTitle    = String(localized: "alert.saveFailed.title")
    static let alertSaveFailedMessage  = String(localized: "alert.saveFailed.message")

    static func alertClearAllTitle(_ categoryTitle: String) -> String {
        String(format: String(localized: "alert.clearAll.title"), categoryTitle)
    }
    static func alertClearAllMessage(_ categoryTitle: String) -> String {
        String(format: String(localized: "alert.clearAll.message"), categoryTitle)
    }

    // MARK: - Toast
    static let toastSaveFailed    = String(localized: "toast.saveFailed")
    static let toastSaveCompleted = String(localized: "toast.saveCompleted")
}
