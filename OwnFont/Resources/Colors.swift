//
//  Colors.swift
//  OwnFont
//
//  Created by 가은 on 4/10/26.
//

import UIKit

extension UIColor {
    // MARK: - Brand Colors

    /// Primary brand color - Coral red (#FF6B6B)
    static let primary = UIColor(hex: "FF6B6B")

    /// Primary color - Dark variant (#E55A5A)
    static let primaryDark = UIColor(hex: "E55A5A")

    /// Primary color - Light tint for backgrounds (#FFF1F1)
    static let primaryLight = UIColor(hex: "FFF1F1")

    /// Primary color - primaryLight보다 약간 진한 연한 핑크 (#FFE0E0)
    static let primarySubtle = UIColor(hex: "FFE0E0")

    // MARK: - Text Colors

    /// Title text color - Dark navy (#1A1A2E)
    static let textTitle = UIColor(hex: "1A1A2E")

    /// Primary text color for body text (#1A1A1A)
    static let textPrimary = UIColor(hex: "1A1A1A")

    /// Secondary text color for descriptions and labels (#666666)
    static let textSecondary = UIColor(hex: "666666")

    /// Tertiary text color for disabled and hint text (#999999)
    static let textTertiary = UIColor(hex: "999999")

    /// Hint text color for placeholders and subtitles (#9CA3AF)
    static let textHint = UIColor(hex: "9CA3AF")

    // MARK: - Background Colors

    /// Background color for main surfaces (#F5F5F5)
    static let background = UIColor(hex: "F5F5F5")

    /// Surface color for cards and components (#FFFFFF)
    static let surface = UIColor(hex: "FFFFFF")

    /// Secondary surface for badges and progress track (#F3F4F6)
    static let surfaceSecondary = UIColor(hex: "F3F4F6")

    // MARK: - Semantic Colors

    /// Info color for links and information highlights (#4A90E2)
    static let info = UIColor(hex: "4A90E2")

    /// Border color for dividers and outlines (#D0D0D0)
    static let border = UIColor(hex: "D0D0D0")

    /// Light border / inactive icon color (#D1D5DB)
    static let borderLight = UIColor(hex: "D1D5DB")

    // MARK: - Success Colors

    /// Success color - Teal green (#10B981)
    static let green = UIColor(hex: "10B981")

    /// Success color - Light variant for backgrounds (#D1FAE5)
    static let greenLight = UIColor(hex: "D1FAE5")

    // MARK: - Accent Colors

    /// Indigo accent (#6366F1)
    static let indigo = UIColor(hex: "6366F1")

    /// Indigo light tint for backgrounds (#EEF2FF)
    static let indigoLight = UIColor(hex: "EEF2FF")

    /// Amber accent (#F59E0B)
    static let amber = UIColor(hex: "F59E0B")

    /// Amber light tint for backgrounds (#FEF3C7)
    static let amberLight = UIColor(hex: "FEF3C7")

    /// Amber dark — 현재 글자 슬롯 텍스트 색상 (#D97706)
    static let amberDark = UIColor(hex: "D97706")

    /// Amber border — 현재 글자 슬롯 테두리 색상 (#FCD34D)
    static let amberBorder = UIColor(hex: "FCD34D")

    // MARK: - Icon Colors

    /// 비활성 아이콘 색상 (#6B7280)
    static let iconInactive = UIColor(hex: "6B7280")
}

// MARK: - Hex Initializer
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
