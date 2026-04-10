//
//  GlyphNormalizer.swift
//  OwnFont
//

import CoreGraphics

/// CGPath(캔버스 좌표) → Em Square(폰트 좌표) 정규화
///
/// ## 좌표계 변환
/// ```
/// iOS 캔버스           Em Square (폰트 관례)
/// (0,0) ─────────     (0, 1000) ─────────
///  │  Y ↓             │  Y ↑
///  │                  │  ascender 영역 (y: 150~1000)
///  └──────── (W, H)   │  baseline      (y: 150)
///                     │  descender 영역 (y: 0~150)
///                     └──────── (1000, 0)
/// ```
///
/// ## 수식
/// ```
/// x' = x × (1000 / W)
/// y' = (1 - y/H) × 850 + 150
///    = -(850/H) × y + 1000
/// ```
/// CGAffineTransform(a: 1000/W, b: 0, c: 0, d: -850/H, tx: 0, ty: 1000)
enum GlyphNormalizer {

    /// Em Square 한 변의 크기 (폰트 업계 표준 UPM)
    static let emSize: CGFloat = 1000

    /// Descender 영역 높이 (em 하단 15%)
    /// 소문자 g, p, y 등의 꼬리가 내려오는 공간
    static let baselineY: CGFloat = 150

    /// 실제 글자가 차지할 수 있는 높이
    static var usableHeight: CGFloat { emSize - baselineY }  // 850

    // MARK: - Public

    /// 캔버스 좌표계의 CGPath를 Em Square 좌표계로 변환합니다.
    ///
    /// - Parameters:
    ///   - path: `DrawingPathExtractor.extract(from:)`가 반환한 캔버스 좌표 경로
    ///   - canvasSize: 드로잉이 그려진 캔버스의 크기 (CharacterCanvasView.bounds.size)
    /// - Returns: Em Square 기준으로 정규화된 CGPath
    static func normalize(_ path: CGPath, canvasSize: CGSize) -> CGPath {
        let transform = emTransform(for: canvasSize)
        let result = CGMutablePath()
        result.addPath(path, transform: transform)
        return result
    }

    // MARK: - Private

    /// 캔버스 → Em Square 아핀 변환 행렬
    ///
    /// CGAffineTransform은 x' = ax + cy + tx, y' = bx + dy + ty
    /// - a  = 1000/W         (x 스케일)
    /// - d  = -850/H         (y 스케일 + 반전)
    /// - ty = 1000           (y 반전 후 em 상단으로 이동)
    private static func emTransform(for canvasSize: CGSize) -> CGAffineTransform {
        CGAffineTransform(
            a:  emSize / canvasSize.width,
            b:  0,
            c:  0,
            d:  -usableHeight / canvasSize.height,
            tx: 0,
            ty: emSize
        )
    }
}
