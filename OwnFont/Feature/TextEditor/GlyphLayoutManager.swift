//
//  GlyphLayoutManager.swift
//  OwnFont
//

import UIKit

final class GlyphLayoutManager: NSLayoutManager {

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let storage = textStorage else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
            return
        }

        let fullText = storage.string as NSString
        let total    = numberOfGlyphs
        let end      = NSMaxRange(glyphsToShow)

        var sysStart = glyphsToShow.location
        var customWork: [(index: Int, path: CGPath)] = []

        for gi in glyphsToShow.location..<end {
            guard gi < total else { break }
            let ci   = characterIndexForGlyph(at: gi)
            guard ci < fullText.length else { continue }
            let char = fullText.substring(with: NSRange(location: ci, length: 1))

            guard let path = resolvedPath(for: char) else { continue }

            if sysStart < gi {
                super.drawGlyphs(forGlyphRange: NSRange(location: sysStart, length: gi - sysStart), at: origin)
            }
            sysStart = gi + 1
            customWork.append((gi, path))
        }

        if sysStart < end {
            super.drawGlyphs(forGlyphRange: NSRange(location: sysStart, length: end - sysStart), at: origin)
        }

        guard !customWork.isEmpty,
              let ctx = UIGraphicsGetCurrentContext() else { return }

        for (gi, normalizedPath) in customWork {
            var effectiveRange = NSRange()
            let lineRect = lineFragmentRect(forGlyphAt: gi, effectiveRange: &effectiveRange)
            let glyphLoc = location(forGlyphAt: gi)

            let baselineX = origin.x + lineRect.minX + glyphLoc.x
            let baselineY = origin.y + lineRect.minY + glyphLoc.y

            let ci    = characterIndexForGlyph(at: gi)
            let attrs = storage.attributes(at: ci, effectiveRange: nil)
            let font  = attrs[.font] as? UIFont ?? .bodyHeader

            let scaleY = font.pointSize / GlyphNormalizer.emSize

            let charStr = fullText.substring(with: NSRange(location: ci, length: 1)) as NSString
            let advanceWidth = charStr.size(withAttributes: [.font: font]).width
            let scaleX = advanceWidth / GlyphNormalizer.emSize

            let transform = CGAffineTransform(
                a:  scaleX, b: 0,
                c:  0,      d: -scaleY,
                tx: baselineX,
                ty: baselineY + GlyphNormalizer.baselineY * scaleY
            )
            let screenPath = CGMutablePath()
            screenPath.addPath(normalizedPath, transform: transform)

            let color = (attrs[.foregroundColor] as? UIColor ?? .label).cgColor

            ctx.saveGState()
            ctx.setStrokeColor(color)
            ctx.setLineWidth(font.pointSize * 0.07)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.addPath(screenPath)
            ctx.strokePath()
            ctx.restoreGState()
        }
    }

    // MARK: - Private

    /// 문자에 대한 정규화된 CGPath 반환
    /// - 영문/숫자/기호: GlyphStore 직접 조회
    /// - 한글 음절: 자모 분해 후 경로 합성
    private func resolvedPath(for char: String) -> CGPath? {
        if let data = GlyphStore.shared.glyph(for: char) {
            return data.normalizedPath
        }
        return hangulComposedPath(for: char)
    }

    private func hangulComposedPath(for char: String) -> CGPath? {
        guard let first = char.first,
              let components = HangulComposer.decompose(first) else { return nil }

        let choKey  = HangulComposer.choseongChars[components.cho]
        let jungKey = HangulComposer.jungseongChars[components.jung]

        guard let choPath  = GlyphStore.shared.glyph(for: choKey)?.normalizedPath,
              let jungPath = GlyphStore.shared.glyph(for: jungKey)?.normalizedPath
        else { return nil }

        let jongPath: CGPath?
        if components.jong >= 0 {
            let jongKey = HangulComposer.jongseongChars[components.jong]
            guard let p = GlyphStore.shared.glyph(for: jongKey)?.normalizedPath else { return nil }
            jongPath = p
        } else {
            jongPath = nil
        }

        return HangulComposer.composePath(cho: choPath, jung: jungPath, jong: jongPath,
                                          jungIndex: components.jung)
    }
}

