//
//  GlyphKerning.swift
//  OwnFont
//

import UIKit

// 커스텀 글리프의 실제 렌더 폭(GlyphLayoutManager 기준)에 맞춰 advance를 .kern 으로 보정
enum GlyphKerning {

    static func apply(to storage: NSTextStorage, fallbackFont: UIFont = .bodyHeader) {
        let text = storage.string as NSString
        let length = text.length
        guard length > 0 else { return }

        storage.beginEditing()
        for i in 0..<length {
            let charRange = NSRange(location: i, length: 1)
            let char = text.substring(with: charRange)
            let font = storage.attribute(.font, at: i, effectiveRange: nil) as? UIFont ?? fallbackFont

            guard let glyphData = GlyphStore.shared.glyph(for: char) else {
                storage.removeAttribute(.kern, range: charRange)
                continue
            }

            let scaleY = font.ascender / GlyphNormalizer.usableHeight
            let bbox = glyphData.normalizedPath.boundingBox
            let renderedWidth = bbox.width * scaleY
            let sideBearing = font.pointSize * 0.12
            let advance = (char as NSString).size(withAttributes: [.font: font]).width
            let kern = renderedWidth + sideBearing - advance
            storage.addAttribute(.kern, value: kern, range: charRange)
        }
        storage.endEditing()
    }
}
