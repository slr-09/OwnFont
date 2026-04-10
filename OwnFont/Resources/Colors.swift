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
    
    /// Primary color - Light variant for backgrounds (#FFE8E8)
    static let primaryLight = UIColor(hex: "FFE8E8")
    
    // MARK: - Text Colors
    
    /// Primary text color for headings and body text (#1A1A1A)
    static let textPrimary = UIColor(hex: "1A1A1A")
    
    /// Secondary text color for descriptions and labels (#666666)
    static let textSecondary = UIColor(hex: "666666")
    
    /// Tertiary text color for disabled and hint text (#999999)
    static let textTertiary = UIColor(hex: "999999")
    
    // MARK: - Background Colors
    
    /// Background color for main surfaces (#F5F5F5)
    static let background = UIColor(hex: "F5F5F5")
    
    /// Surface color for cards and components (#FFFFFF)
    static let surface = UIColor(hex: "FFFFFF")
    
    // MARK: - Semantic Colors
    
    /// Info color for links and information highlights (#4A90E2)
    static let info = UIColor(hex: "4A90E2")
    
    /// Border color for dividers and outlines (#D0D0D0)
    static let border = UIColor(hex: "D0D0D0")

    // MARK: - Success Colors

    /// Success color - Teal green (#10B981)
    static let green = UIColor(hex: "10B981")

    /// Success color - Light variant for backgrounds (#D1FAE5)
    static let greenLight = UIColor(hex: "D1FAE5")
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
