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

            // 종횡비 유지(scaleX == scaleY)로 사용자가 그린 비율 그대로 렌더링.
            // 캔버스 좌측의 빈 공간(left bearing)은 bbox 기준으로 제거하여
            // 글리프 ink의 좌측 끝이 baselineX(커서 진행 지점)에 붙도록 한다.
            let scaleY = font.ascender / GlyphNormalizer.usableHeight
            let scaleX = scaleY

            let bbox = glyphData.normalizedPath.boundingBox
            let leftShift = -bbox.minX
            let fitTransform = CGAffineTransform(translationX: leftShift, y: 0)
            let renderTransform = CGAffineTransform(
                a:  scaleX, b: 0,
                c:  0,      d: -scaleY,
                tx: baselineX,
                ty: baselineY + GlyphNormalizer.baselineY * scaleY
            )
            let combined = fitTransform.concatenating(renderTransform)
            let screenPath = CGMutablePath()
            screenPath.addPath(glyphData.normalizedPath, transform: combined)

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

