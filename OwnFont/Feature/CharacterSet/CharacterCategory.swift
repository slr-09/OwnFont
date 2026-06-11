//
//  CharacterCategory.swift
//  OwnFont
//

import UIKit

enum CharacterCategory: CaseIterable {
    case lowercaseLatin
    case uppercaseLatin
    case number
    case symbol
    case hangulChoseong
    case hangulJungseong

    var title: String {
        switch self {
        case .lowercaseLatin:   return "영문 소문자"
        case .uppercaseLatin:   return "영문 대문자"
        case .number:           return "숫자"
        case .symbol:           return "특수문자"
        case .hangulChoseong:   return "한글 자음"
        case .hangulJungseong:  return "한글 모음"
        }
    }

    var rangeLabel: String {
        switch self {
        case .lowercaseLatin:   return "a–z"
        case .uppercaseLatin:   return "A–Z"
        case .number:           return "0–9"
        case .symbol:           return "!@#…"
        case .hangulChoseong:   return "ㄱ–ㅎ"
        case .hangulJungseong:  return "ㅏ–ㅣ"
        }
    }

    var totalCount: Int {
        switch self {
        case .lowercaseLatin:   return 26
        case .uppercaseLatin:   return 26
        case .number:           return 10
        case .symbol:           return 20
        case .hangulChoseong:   return 19
        case .hangulJungseong:  return 14
        }
    }

    func subtitle(completedCount: Int) -> String {
        "\(rangeLabel) · \(completedCount) / \(totalCount)자 완료"
    }

    var characters: [String] {
        switch self {
        case .lowercaseLatin:
            return (Unicode.Scalar("a").value...Unicode.Scalar("z").value)
                .compactMap { Unicode.Scalar($0).map { String($0) } }
        case .uppercaseLatin:
            return (Unicode.Scalar("A").value...Unicode.Scalar("Z").value)
                .compactMap { Unicode.Scalar($0).map { String($0) } }
        case .number:
            return Array("0123456789").map { String($0) }
        case .symbol:
            return Array("!@#$%^&*()-_+=[]{}:;/:").prefix(20).map { String($0) }
        case .hangulChoseong:
            return HangulComposer.choseongChars
        case .hangulJungseong:
            return HangulComposer.basicJungseongChars
        }
    }

    var iconName: String {
        switch self {
        case .lowercaseLatin:   return "textformat.abc"
        case .uppercaseLatin:   return "abc"
        case .number:           return "number"
        case .symbol:           return "sparkles"
        case .hangulChoseong:   return "character"
        case .hangulJungseong:  return "character"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .lowercaseLatin:   return .primary
        case .uppercaseLatin:   return .indigo
        case .number:           return .green
        case .symbol:           return .amber
        case .hangulChoseong:   return .sky
        case .hangulJungseong:  return .violet
        }
    }

    var iconBgColor: UIColor {
        switch self {
        case .lowercaseLatin:   return .primaryLight
        case .uppercaseLatin:   return .indigoLight
        case .number:           return .greenLight
        case .symbol:           return .amberLight
        case .hangulChoseong:   return .skyLight
        case .hangulJungseong:  return .violetLight
        }
    }
}
