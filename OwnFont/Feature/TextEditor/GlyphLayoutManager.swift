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

            // Y축: 캔버스의 usable 영역(baseline 위)이 font.ascender와 일치하도록 스케일
            // scaleY = font.ascender / usableHeight → em 250~1000(750 units) = font.ascender 높이
            let scaleY = font.ascender / GlyphNormalizer.usableHeight

            // X축: 종횡비 유지 (scaleX = scaleY × advanceWidth/pointSize)
            // 한글처럼 advance ≈ pointSize인 경우 scaleX ≈ scaleY로 왜곡 없음
            let charStr = fullText.substring(with: NSRange(location: ci, length: 1)) as NSString
            let advanceWidth = charStr.size(withAttributes: [.font: font]).width
            let scaleX = font.pointSize > 0 ? scaleY * (advanceWidth / font.pointSize) : scaleY

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

