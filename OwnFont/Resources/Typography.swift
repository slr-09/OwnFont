//
//  Typography.swift
//  OwnFont
//
//  Created by 가은 on 4/10/26.
//

import UIKit

extension UIFont {
    private static let fontName = "NoonnuBasicGothicRegular"

    // MARK: - Headline

    /// Headline style - 28px Bold
    static let headline = UIFont(name: fontName, size: 28) ?? UIFont.boldSystemFont(ofSize: 28)

    // MARK: - Body Header

    /// Body Header style - 16px Regular
    static let bodyHeader = UIFont(name: fontName, size: 16) ?? UIFont.systemFont(ofSize: 16)

    // MARK: - Body

    /// Body style - 14px Regular
    static let body = UIFont(name: fontName, size: 14) ?? UIFont.systemFont(ofSize: 14)

    // MARK: - Card Title

    /// Card title - 24px Bold
    static let cardTitle = UIFont(name: fontName, size: 24) ?? UIFont.boldSystemFont(ofSize: 24)

    // MARK: - Card Header

    /// Card header - 16px Regular
    static let cardHeader = UIFont(name: fontName, size: 16) ?? UIFont.systemFont(ofSize: 16)

    // MARK: - Caption

    /// Caption - 12px Regular
    static let caption = UIFont(name: fontName, size: 12) ?? UIFont.systemFont(ofSize: 12)

    // MARK: - Badge

    /// Badge - 11px Regular
    static let badge = UIFont(name: fontName, size: 11) ?? UIFont.systemFont(ofSize: 11)

    // MARK: - Sub Label

    /// Sub label - 13px Regular
    static let subLabel = UIFont(name: fontName, size: 13) ?? UIFont.systemFont(ofSize: 13)
    
    static let guideLabel = UIFont(name: fontName, size: 160) ?? UIFont.systemFont(ofSize: 130, weight: .heavy)

    static func custom(size: CGFloat) -> UIFont {
        UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
