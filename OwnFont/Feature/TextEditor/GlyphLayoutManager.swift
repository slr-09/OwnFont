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

            // Y축: 캔버스의 usable 영역(baseline 위)이 font.ascender와 일치하도록 스케일.
            // 종횡비 유지(scaleX == scaleY)로 사용자가 그린 비율 그대로 렌더링.
            // 캔버스 좌측의 빈 공간(left bearing)은 bbox 기준으로 제거하여
            // 글리프 ink의 좌측 끝이 baselineX(커서 진행 지점)에 붙도록 한다.
            let scaleY = font.ascender / GlyphNormalizer.usableHeight
            let scaleX = scaleY

            let bbox = normalizedPath.boundingBox
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
            screenPath.addPath(normalizedPath, transform: combined)

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
            // 종성은 초성 글리프로 합성 (겹받침은 초성 2개를 나란히 배치)
            guard let p = HangulComposer.composeJongseong(jongIndex: components.jong, choPath: {
                GlyphStore.shared.glyph(for: $0)?.normalizedPath
            }) else { return nil }
            jongPath = p
        } else {
            jongPath = nil
        }

        return HangulComposer.composePath(cho: choPath, jung: jungPath, jong: jongPath,
                                          jungIndex: components.jung)
    }
}

