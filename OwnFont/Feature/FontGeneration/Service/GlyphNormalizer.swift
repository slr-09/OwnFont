//
//  GlyphNormalizer.swift
//  OwnFont
//

import CoreGraphics

/// CGPath(캔버스 좌표) → Em Square(폰트 좌표) 정규화
///
/// ## 좌표계 변환
/// ```
/// iOS 캔버스 (정사각형)    Em Square (폰트 관례)
/// (0,0) ─────────        (0, 1000) ─────────
///  │  Y ↓                │  Y ↑
///  │  ── 베이스라인(85%)  │  ascender 영역 (y: 150~1000)
///  └──────── (W, W)      │  baseline      (y: 150)
///                        │  descender 영역 (y: 0~150)
///                        └──────── (1000, 0)
/// ```
///
/// ## 수식 (캔버스 = em 전체 표현, W=H)
/// ```
/// x' = x × (1000 / W)
/// y' = (1 - y/H) × 1000
///    = -(1000/H) × y + 1000
/// ```
/// → x/y 스케일 동일(1000/W) → 등비 변환, 왜곡 없음
/// → 베이스라인(em 150)은 캔버스 상단 85% 지점
enum GlyphNormalizer {

    /// Em Square 한 변의 크기 (폰트 업계 표준 UPM)
    static let emSize: CGFloat = 1000

    /// Descender 영역 높이 (em 하단 25%)
    static let baselineY: CGFloat = 250

    /// 실제 글자가 차지할 수 있는 높이
    static var usableHeight: CGFloat { emSize - baselineY }  // 850

    /// 캔버스에서 베이스라인 위치 비율 (상단으로부터)
    static var baselineRatio: CGFloat { usableHeight / emSize }  // 0.85

    // MARK: - Public

    static func normalize(_ path: CGPath, canvasSize: CGSize) -> CGPath {
        let transform = emTransform(for: canvasSize)
        let result = CGMutablePath()
        result.addPath(path, transform: transform)
        return result
    }

    // MARK: - Private

    /// 캔버스(정사각형) → Em Square 아핀 변환 행렬
    ///
    /// - a  = 1000/W  (x 스케일)
    /// - d  = -1000/H (y 스케일 + 반전, W=H이면 x와 동일 → 등비)
    /// - ty = 1000    (y 반전 후 em 상단으로 이동)
    private static func emTransform(for canvasSize: CGSize) -> CGAffineTransform {
        CGAffineTransform(
            a:  emSize / canvasSize.width,
            b:  0,
            c:  0,
            d:  -emSize / canvasSize.height,
            tx: 0,
            ty: emSize
        )
    }
}
