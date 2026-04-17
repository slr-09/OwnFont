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
        var customWork: [(index: Int, data: GlyphData)] = []

        for gi in glyphsToShow.location..<end {
            guard gi < total else { break }
            let ci   = characterIndexForGlyph(at: gi)
            guard ci < fullText.length else { continue }
            let char = fullText.substring(with: NSRange(location: ci, length: 1))

            guard let data = GlyphStore.shared.glyph(for: char) else { continue }

            if sysStart < gi {
                super.drawGlyphs(forGlyphRange: NSRange(location: sysStart, length: gi - sysStart), at: origin)
            }
            sysStart = gi + 1
            customWork.append((gi, data))
        }

        if sysStart < end {
            super.drawGlyphs(forGlyphRange: NSRange(location: sysStart, length: end - sysStart), at: origin)
        }

        guard !customWork.isEmpty,
              let ctx = UIGraphicsGetCurrentContext() else { return }

        for (gi, glyphData) in customWork {
            var effectiveRange = NSRange()
            let lineRect = lineFragmentRect(forGlyphAt: gi, effectiveRange: &effectiveRange)
            let glyphLoc = location(forGlyphAt: gi)

            let baselineX = origin.x + lineRect.minX + glyphLoc.x
            let baselineY = origin.y + lineRect.minY + glyphLoc.y

            let ci    = characterIndexForGlyph(at: gi)
            let attrs = storage.attributes(at: ci, effectiveRange: nil)
            let font  = attrs[.font] as? UIFont ?? .bodyHeader

            // Y축: 폰트 사이즈 기준 (시각적 높이 유지)
            let scaleY = font.pointSize / GlyphNormalizer.emSize

            // X축: 시스템 advance width 기준
            // 커서는 advance 끝에 놓이므로, 글리프가 advance를 넘으면 커서와 겹침
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
            screenPath.addPath(glyphData.normalizedPath, transform: transform)

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
}

