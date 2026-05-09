//
//  HangulComposer.swift
//  OwnFont
//

import CoreGraphics

/// 한글 음절의 자모 분해 및 경로 합성 엔진
///
/// ## 유니코드 구조
/// 음절 코드포인트 = 0xAC00 + (초성 × 588) + (중성 × 28) + 종성
///
/// ## 자모 저장 키 (Hangul Jamo 블록)
/// - 초성: U+1100–U+1112 (19자) — 종성과 Unicode 코드포인트가 달라 충돌 없음
/// - 중성: U+1161–U+1175 (21자)
/// - 종성: U+11A8–U+11C2 (27자)
enum HangulComposer {

    // MARK: - Jamo Unicode Arrays

    /// 초성 19자 (U+1100–U+1112)
    static let choseongChars: [String] = (0..<19).map {
        String(Unicode.Scalar(0x1100 + UInt32($0))!)
    }

    /// 중성 21자 (U+1161–U+1175)
    static let jungseongChars: [String] = (0..<21).map {
        String(Unicode.Scalar(0x1161 + UInt32($0))!)
    }

    /// 종성 27자 (U+11A8–U+11C2)
    static let jongseongChars: [String] = (0..<27).map {
        String(Unicode.Scalar(0x11A8 + UInt32($0))!)
    }

    // MARK: - Decomposition

    /// 한글 음절을 초성/중성/종성 인덱스로 분해
    ///
    /// - Returns: `(cho: 0–18, jung: 0–20, jong: 0–26)` — 받침 없으면 `jong = -1`
    ///            한글 음절이 아니면 `nil`
    static func decompose(_ character: Character) -> (cho: Int, jung: Int, jong: Int)? {
        guard let scalar = character.unicodeScalars.first else { return nil }
        let value = scalar.value
        guard value >= 0xAC00, value <= 0xD7A3 else { return nil }

        let offset = value - 0xAC00
        let jong   = Int(offset % 28)
        let jung   = Int((offset / 28) % 21)
        let cho    = Int(offset / 588)

        return (cho: cho, jung: jung, jong: jong == 0 ? -1 : jong - 1)
    }

    // MARK: - Vowel Classification

    /// 중성이 세로 모음(ㅏ ㅐ ㅑ ㅒ ㅓ ㅔ ㅕ ㅖ ㅣ)인지 여부
    ///
    /// - 세로 모음: 초성(좌) + 중성(우) 배치
    /// - 가로 모음: 초성(상) + 중성(하) 배치
    static func isVerticalVowel(_ jungIndex: Int) -> Bool {
        jungIndex <= 7 || jungIndex == 20
    }

    // MARK: - Path Composition

    /// 초성/중성/종성 경로를 배치 규칙에 따라 Em Square 내에 합성
    ///
    /// 모든 입력 경로는 Em Square(0,0)–(1000,1000) Y↑ 좌표계를 사용해야 함.
    static func composePath(cho: CGPath, jung: CGPath, jong: CGPath?, jungIndex: Int) -> CGPath {
        let em: CGFloat   = GlyphNormalizer.emSize      // 1000
        let base: CGFloat = GlyphNormalizer.baselineY   // 250
        let hasJong       = jong != nil
        let vertical      = isVerticalVowel(jungIndex)

        let choZone: CGRect
        let jungZone: CGRect
        var jongZone: CGRect?

        if vertical {
            if hasJong {
                // 초성(좌상) + 중성(우상) + 종성(하단 전체)
                choZone  = CGRect(x: 0,   y: 380, width: 580, height: 620)
                jungZone = CGRect(x: 540, y: 380, width: 460, height: 620)
                jongZone = CGRect(x: 50,  y: base, width: 900, height: 260)
            } else {
                // 초성(좌) + 중성(우)
                choZone  = CGRect(x: 0,   y: base, width: 580, height: em - base)
                jungZone = CGRect(x: 540, y: base, width: 460, height: em - base)
            }
        } else {
            if hasJong {
                // 초성(상) + 중성(중) + 종성(하)
                choZone  = CGRect(x: 50, y: 640, width: 900, height: 360)
                jungZone = CGRect(x: 50, y: 310, width: 900, height: 350)
                jongZone = CGRect(x: 50, y: base, width: 900, height: 180)
            } else {
                // 초성(상) + 중성(하)
                choZone  = CGRect(x: 50, y: 520, width: 900, height: 480)
                jungZone = CGRect(x: 50, y: base, width: 900, height: 390)
            }
        }

        let result = CGMutablePath()
        result.addPath(cho,  transform: fitTransform(in: choZone,  emSize: em))
        result.addPath(jung, transform: fitTransform(in: jungZone, emSize: em))
        if let jong, let jongZone {
            result.addPath(jong, transform: fitTransform(in: jongZone, emSize: em))
        }
        return result
    }

    // MARK: - Private

    /// Em Square([0,0]–[em,em]) 좌표의 경로를 목표 rect에 맞게 스케일·이동하는 변환
    private static func fitTransform(in rect: CGRect, emSize: CGFloat) -> CGAffineTransform {
        CGAffineTransform(
            a:  rect.width  / emSize,
            b:  0,
            c:  0,
            d:  rect.height / emSize,
            tx: rect.minX,
            ty: rect.minY
        )
    }
}
