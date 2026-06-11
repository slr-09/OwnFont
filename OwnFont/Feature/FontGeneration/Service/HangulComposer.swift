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

    /// 중성 21자의 호환 자모 표기 (`jungseongChars`와 동일 순서, 소스 가독성용)
    private static let jungseongCompat = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")

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

    /// 단독 입력된 호환 자모(ㄱ, ㅏ 등)에 대응하는 저장 글리프 키.
    ///
    /// 조합 중인 음절(예: "붹" → ㅂ → 부 → 붸 → 붹)의 첫 단계처럼 자모 하나만 있을 때,
    /// 초성 자음이면 초성 글리프, 모음이면 중성 글리프로 렌더링하기 위한 매핑. 없으면 `nil`.
    static func standaloneGlyphKey(for char: Character) -> String? {
        if let i = choseongCompat.firstIndex(of: char)  { return choseongChars[i] }
        if let i = jungseongCompat.firstIndex(of: char) { return jungseongChars[i] }
        return nil
    }

    // MARK: - Vowel Classification

    /// 중성 모양에 따른 초성·중성 배치 유형
    enum VowelLayout {
        case right   // 세로 모음: 초성(좌) + 중성(우)        — ㅏㅐㅑㅒㅓㅔㅕㅖ ㅣ
        case bottom  // 가로 모음: 초성(상) + 중성(하)        — ㅗㅛㅜㅠㅡ
        case mixed   // 복합 모음: 초성(좌상) + 중성(우·하)   — ㅘㅙㅚㅝㅞㅟㅢ
    }

    /// 중성 인덱스(0–20)의 배치 유형 분류
    static func vowelLayout(_ jungIndex: Int) -> VowelLayout {
        switch jungIndex {
        case 0...7, 20:                 return .right
        case 9, 10, 11, 14, 15, 16, 19: return .mixed
        default:                        return .bottom   // 8(ㅗ) 12(ㅛ) 13(ㅜ) 17(ㅠ) 18(ㅡ)
        }
    }

    /// 복합 중성 → (가로 성분, 세로 성분)의 기본 중성 인덱스. 복합 모음이 아니면 `nil`.
    ///
    /// 가로 성분(ㅗ/ㅜ/ㅡ)은 초성 아래에, 세로 성분(ㅏ/ㅐ/ㅓ/ㅔ/ㅣ)은 초성 오른쪽에 배치된다.
    static func mixedVowelComponents(_ jungIndex: Int) -> (horizontal: Int, vertical: Int)? {
        switch jungIndex {
        case 9:  return (8, 0)    // ㅘ = ㅗ + ㅏ
        case 10: return (8, 1)    // ㅙ = ㅗ + ㅐ
        case 11: return (8, 20)   // ㅚ = ㅗ + ㅣ
        case 14: return (13, 4)   // ㅝ = ㅜ + ㅓ
        case 15: return (13, 5)   // ㅞ = ㅜ + ㅔ
        case 16: return (13, 20)  // ㅟ = ㅜ + ㅣ
        case 19: return (18, 20)  // ㅢ = ㅡ + ㅣ
        default: return nil
        }
    }

    /// 직접 입력받는 기본 중성 14자 (복합 모음 ㅘㅙㅚㅝㅞㅟㅢ 제외 — 기본 모음으로 합성됨)
    static let basicJungseongChars: [String] = (0..<jungseongChars.count)
        .filter { mixedVowelComponents($0) == nil }
        .map { jungseongChars[$0] }

    // MARK: - Path Composition

    /// 초성/중성/종성 경로를 배치 규칙에 따라 Em Square 내에 합성
    ///
    /// - jung: 단일 모음. 복합 모음일 때는 가로 성분(ㅗ/ㅜ/ㅡ).
    /// - jungExtra: 복합 모음의 세로 성분(ㅏ/ㅐ/ㅓ/ㅔ/ㅣ). 그 외에는 `nil`.
    /// 모든 입력 경로는 Em Square(0,0)–(1000,1000) Y↑ 좌표계를 사용해야 함.
    static func composePath(cho: CGPath, jung: CGPath, jungExtra: CGPath? = nil,
                            jong: CGPath?, jungIndex: Int) -> CGPath {
        let hasJong = jong != nil
        let layout  = vowelLayout(jungIndex)
        let result  = CGMutablePath()

        switch layout {
        case .right:
            // 초성(좌) + 중성(우) — 초성은 오른쪽, 중성은 왼쪽으로 정렬해 간격을 좁힌다.
            if hasJong {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 40,  y: 570, width: 470, height: 430), alignX: 1, alignY: 0.5))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 620, y: 570, width: 340, height: 430), alignX: 0, alignY: 0.5))
            } else {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 40,  y: 250, width: 470, height: 750), alignX: 1, alignY: 0.5))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 620, y: 250, width: 340, height: 750), alignX: 0, alignY: 0.5))
            }
        case .bottom:
            // 초성(상) + 중성(하) — 초성은 아래, 중성은 위로 정렬해 간격을 좁힌다.
            if hasJong {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 120, y: 740, width: 760, height: 260), alignX: 0.5, alignY: 0))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 100, y: 500, width: 800, height: 150), alignX: 0.5, alignY: 0.5))
            } else {
                result.addPath(cho,  transform: fit(cho,  into: CGRect(x: 120, y: 560, width: 760, height: 440), alignX: 0.5, alignY: 0))
                result.addPath(jung, transform: fit(jung, into: CGRect(x: 100, y: 250, width: 800, height: 220), alignX: 0.5, alignY: 1))
            }
        case .mixed:
            // 복합 모음(ㅘㅙㅚㅝㅞㅟㅢ): 초성(좌상) + 가로성분(초성 아래) + 세로성분(우측 전체)
            let jungV = jungExtra ?? jung   // 세로 성분 (분해 실패 시 jung으로 폴백)
            // 초성(좌상) + 가로성분(초성 아래, 크게) + 세로성분(우측, 바닥까지) — 모두 비율 유지
            if hasJong {
                result.addPath(cho,   transform: fit(cho,   into: CGRect(x: 60,  y: 700, width: 440, height: 280), alignX: 0.5, alignY: 0.5))
                result.addPath(jung,  transform: fit(jung,  into: CGRect(x: 40,  y: 480, width: 580, height: 190), alignX: 0.5, alignY: 0.5))
                result.addPath(jungV, transform: fit(jungV, into: CGRect(x: 600, y: 480, width: 360, height: 500), alignX: 0, alignY: 0.5))
            } else {
                result.addPath(cho,   transform: fit(cho,   into: CGRect(x: 60,  y: 620, width: 440, height: 360), alignX: 0.5, alignY: 0.5))
                result.addPath(jung,  transform: fit(jung,  into: CGRect(x: 40,  y: 300, width: 580, height: 280), alignX: 0.5, alignY: 0.5))
                result.addPath(jungV, transform: fit(jungV, into: CGRect(x: 600, y: 250, width: 360, height: 730), alignX: 0, alignY: 0.5))
            }
        }

        if let jong {
            // 받침은 가로로 넓고 납작한 형태(실제 폰트 관례)이므로 비율 유지 없이 칸을 채운다.
            let zone = layout == .right
                ? CGRect(x: 260, y: 250, width: 480, height: 230)
                : CGRect(x: 220, y: 250, width: 560, height: 230)
            result.addPath(jong, transform: fill(jong, into: zone))
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

    /// 경로의 실제 ink를 목표 rect에 가득 채우는 변환 (가로·세로 독립 스케일, 비율 미유지).
    private static func fill(_ path: CGPath, into rect: CGRect) -> CGAffineTransform {
        let b = path.boundingBoxOfPath
        guard b.width > .ulpOfOne, b.height > .ulpOfOne else { return .identity }
        let sx = rect.width  / b.width
        let sy = rect.height / b.height
        return CGAffineTransform(
            a: sx, b: 0, c: 0, d: sy,
            tx: rect.minX - b.minX * sx,
            ty: rect.minY - b.minY * sy
        )
    }
}
