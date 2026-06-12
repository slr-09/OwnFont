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
        var customWork: [(index: Int, path: CGPath, isHangul: Bool)] = []

        for gi in glyphsToShow.location..<end {
            guard gi < total else { break }
            let ci   = characterIndexForGlyph(at: gi)
            guard ci < fullText.length else { continue }
            let char = fullText.substring(with: NSRange(location: ci, length: 1))

            guard let path = resolvedPath(for: char) else { continue }

            // 한글 음절(가–힣) + 조합 중 단독 자모(호환 자모 ㄱ–ㅣ)는 advance 칸에 맞춰 그린다
            let isHangul = char.unicodeScalars.first.map {
                ($0.value >= 0xAC00 && $0.value <= 0xD7A3) || ($0.value >= 0x3131 && $0.value <= 0x3163)
            } ?? false

            if sysStart < gi {
                super.drawGlyphs(forGlyphRange: NSRange(location: sysStart, length: gi - sysStart), at: origin)
            }
            sysStart = gi + 1
            customWork.append((gi, path, isHangul))
        }

        if sysStart < end {
            super.drawGlyphs(forGlyphRange: NSRange(location: sysStart, length: end - sysStart), at: origin)
        }

        guard !customWork.isEmpty,
              let ctx = UIGraphicsGetCurrentContext() else { return }

        for (gi, normalizedPath, isHangul) in customWork {
            var effectiveRange = NSRange()
            let lineRect = lineFragmentRect(forGlyphAt: gi, effectiveRange: &effectiveRange)
            let glyphLoc = location(forGlyphAt: gi)

            let baselineX = origin.x + lineRect.minX + glyphLoc.x
            let baselineY = origin.y + lineRect.minY + glyphLoc.y

            let ci    = characterIndexForGlyph(at: gi)
            let attrs = storage.attributes(at: ci, effectiveRange: nil)
            let font  = attrs[.font] as? UIFont ?? .bodyHeader

            let combined: CGAffineTransform
            if isHangul {
                // 한글: 합성된 음절(em 0–1000)을 글자 칸(advance) 폭에 등비로 맞춘다.
                // advance는 폰트 메트릭에서 직접 계산 — 레이아웃 위치(포커스 시 캐럿·줄 끝
                // 여백으로 값이 달라짐)에 의존하지 않으므로 포커스 상태와 무관하게 동일 크기.
                let ch = fullText.substring(with: NSRange(location: ci, length: 1))
                let advance = (ch as NSString).size(withAttributes: [.font: font]).width
                let scale = advance / GlyphNormalizer.emSize
                combined = CGAffineTransform(
                    a:  scale, b: 0,
                    c:  0,     d: -scale,
                    tx: baselineX,
                    ty: baselineY + GlyphNormalizer.baselineY * scale
                )
            } else {
                // 영문/숫자/기호: 종횡비 유지(scaleX == scaleY)로 사용자가 그린 비율 그대로.
                // 좌측 빈 공간(left bearing)은 bbox로 제거해 ink 좌측 끝을 baselineX에 붙인다.
                let scale = font.ascender / GlyphNormalizer.usableHeight
                let bbox = normalizedPath.boundingBox
                let leftShift = CGAffineTransform(translationX: -bbox.minX, y: 0)
                let renderTransform = CGAffineTransform(
                    a:  scale, b: 0,
                    c:  0,     d: -scale,
                    tx: baselineX,
                    ty: baselineY + GlyphNormalizer.baselineY * scale
                )
                combined = leftShift.concatenating(renderTransform)
            }

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
        // 조합 중 단독 자모(호환 자모 ㅂ·ㅏ 등) → 음절 자모 위치에 배치해 렌더
        if let first = char.first,
           let info = HangulComposer.standaloneGlyph(for: first),
           let raw = GlyphStore.shared.glyph(for: info.key)?.normalizedPath {
            return HangulComposer.composeStandalone(path: raw, isConsonant: info.isConsonant)
        }
        return hangulComposedPath(for: char)
    }

    private func hangulComposedPath(for char: String) -> CGPath? {
        guard let first = char.first,
              let components = HangulComposer.decompose(first) else { return nil }

        let choKey = HangulComposer.choseongChars[components.cho]
        guard let choPath = GlyphStore.shared.glyph(for: choKey)?.normalizedPath else { return nil }

        // 중성: 복합 모음(ㅚ·ㅞ 등)이면 가로/세로 기본 모음 글리프로 분해
        let jungPath: CGPath
        let jungExtraPath: CGPath?
        if let parts = HangulComposer.mixedVowelComponents(components.jung) {
            guard let h = GlyphStore.shared.glyph(for: HangulComposer.jungseongChars[parts.horizontal])?.normalizedPath,
                  let v = GlyphStore.shared.glyph(for: HangulComposer.jungseongChars[parts.vertical])?.normalizedPath
            else { return nil }
            jungPath = h
            jungExtraPath = v
        } else {
            guard let j = GlyphStore.shared.glyph(for: HangulComposer.jungseongChars[components.jung])?.normalizedPath
            else { return nil }
            jungPath = j
            jungExtraPath = nil
        }

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

        return HangulComposer.composePath(cho: choPath, jung: jungPath, jungExtra: jungExtraPath,
                                          jong: jongPath, jungIndex: components.jung)
    }
}

