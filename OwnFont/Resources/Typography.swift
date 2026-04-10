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
}
