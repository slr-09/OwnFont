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

    // MARK: - Jongseong → Choseong Composition

    /// 초성 19자의 호환 자모 표기 (`choseongChars`와 동일 순서, 소스 가독성용)
    private static let choseongCompat = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")

    /// 종성 27자를 구성하는 초성 (`jongseongChars`와 동일 순서, 호환 자모 표기)
    ///
    /// 홑받침은 1글자, 겹받침은 초성 2글자로 분해 — 종성은 모두 초성 글리프로 합성 가능하다.
    private static let jongComponents: [String] = [
        "ㄱ", "ㄲ", "ㄱㅅ", "ㄴ", "ㄴㅈ", "ㄴㅎ", "ㄷ",
        "ㄹ", "ㄹㄱ", "ㄹㅁ", "ㄹㅂ", "ㄹㅅ", "ㄹㅌ", "ㄹㅍ", "ㄹㅎ",
        "ㅁ", "ㅂ", "ㅂㅅ", "ㅅ", "ㅆ", "ㅇ",
        "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
    ]

    /// 종성 경로를 초성 글리프로부터 합성
    ///
    /// - Parameters:
    ///   - jongIndex: 종성 인덱스(0–26)
    ///   - choPath: 초성 저장 키(`choseongChars`의 원소) → Em Square 정규화 경로 조회 클로저
    /// - Returns: 합성된 종성 경로 (Em Square 0,0–1000,1000 Y↑). 구성 초성 누락 시 `nil`
    static func composeJongseong(jongIndex: Int, choPath: (String) -> CGPath?) -> CGPath? {
        guard jongIndex >= 0, jongIndex < jongComponents.count else { return nil }
        let components = jongComponents[jongIndex]

        // 호환 자모로 표기된 구성 초성을 저장 키(conjoining)로 변환 후 경로 조회
        let paths = components.compactMap { comp -> CGPath? in
            guard let idx = choseongCompat.firstIndex(of: comp) else { return nil }
            return choPath(choseongChars[idx])
        }
        guard paths.count == components.count else { return nil }

        // 홑받침: 초성 글리프 그대로 사용
        if paths.count == 1 { return paths[0] }

        // 겹받침: 두 초성을 좌·우 절반에 안쪽 정렬로 나란히 배치
        let em = GlyphNormalizer.emSize
        let result = CGMutablePath()
        result.addPath(paths[0], transform: fit(paths[0], into: CGRect(x: 0,         y: 0, width: em * 0.48, height: em), alignX: 1, alignY: 0.5))
        result.addPath(paths[1], transform: fit(paths[1], into: CGRect(x: em * 0.52, y: 0, width: em * 0.48, height: em), alignX: 0, alignY: 0.5))
        return result
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
        let hasJong  = jong != nil
        let vertical = isVerticalVowel(jungIndex)
        let result   = CGMutablePath()

        if vertical {
            // 초성(좌) + 중성(우) — 초성은 오른쪽, 중성은 왼쪽으로 정렬해 간격을 좁힌다.
            if hasJong {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 40,  y: 540, width: 470, height: 460), alignX: 1, alignY: 0.5))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 620, y: 540, width: 340, height: 460), alignX: 0, alignY: 0.5))
            } else {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 40,  y: 250, width: 470, height: 750), alignX: 1, alignY: 0.5))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 620, y: 250, width: 340, height: 750), alignX: 0, alignY: 0.5))
            }
        } else {
            // 초성(상) + 중성(하) — 초성은 아래, 중성은 위로 정렬해 간격을 좁힌다.
            if hasJong {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 120, y: 720, width: 760, height: 280), alignX: 0.5, alignY: 0))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 100, y: 510, width: 800, height: 170), alignX: 0.5, alignY: 0.5))
            } else {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 120, y: 540, width: 760, height: 460), alignX: 0.5, alignY: 0))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 100, y: 250, width: 800, height: 250), alignX: 0.5, alignY: 1))
            }
        }

        if let jong {
            let zone = vertical
                ? CGRect(x: 170, y: 250, width: 660, height: 270)
                : CGRect(x: 120, y: 250, width: 760, height: 230)
            result.addPath(jong, transform: fit(jong, into: zone, alignX: 0.5, alignY: 0.5))
        }
        return result
    }

    // MARK: - Private

    /// 경로의 실제 ink(boundingBoxOfPath)를 목표 rect에 비율 유지(aspect-fit)로 맞추는 변환.
    ///
    /// - alignX/alignY: rect 내 정렬 비율 (0 = 좌/하, 0.5 = 중앙, 1 = 우/상)
    private static func fit(_ path: CGPath, into rect: CGRect,
                            alignX: CGFloat, alignY: CGFloat) -> CGAffineTransform {
        let b = path.boundingBoxOfPath
        guard b.width > .ulpOfOne, b.height > .ulpOfOne else { return .identity }
        let scale = min(rect.width / b.width, rect.height / b.height)
        let w = b.width * scale
        let h = b.height * scale
        return CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale,
            tx: rect.minX + (rect.width  - w) * alignX - b.minX * scale,
            ty: rect.minY + (rect.height - h) * alignY - b.minY * scale
        )
    }
}
