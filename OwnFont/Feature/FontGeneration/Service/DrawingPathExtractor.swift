//
//  DrawingPathExtractor.swift
//  OwnFont
//

import PencilKit
import CoreGraphics

/// PKDrawing → CGPath 변환
///
/// PKDrawing의 모든 획(PKStroke)을 순회해 하나의 CGPath로 합칩니다.
/// 각 획은 중점 이분법(midpoint subdivision) 알고리즘으로 스무딩됩니다.
enum DrawingPathExtractor {

    /// PKDrawing에서 CGPath를 추출합니다.
    /// - Parameter drawing: PKCanvasView에서 얻은 드로잉 데이터
    /// - Returns: 모든 획이 합쳐진 CGPath (캔버스 좌표계, Y↓)
    static func extract(from drawing: PKDrawing) -> CGPath {
        let combined = CGMutablePath()

        for stroke in drawing.strokes {
            let strokePath = buildPath(from: stroke.path)
            // 각 획의 자체 transform(이동·회전) 반영
            combined.addPath(strokePath, transform: stroke.transform)
        }

        return combined
    }

    // MARK: - Private

    /// PKStrokePath → CGPath
    private static func buildPath(from strokePath: PKStrokePath) -> CGPath {
        guard strokePath.count > 0 else { return CGMutablePath() }

        // PKStrokePath는 RandomAccessCollection<PKStrokePoint>
        let points = (0..<strokePath.count).map { strokePath[$0].location }
        return smoothPath(from: points)
    }

    /// 중점 이분법(midpoint subdivision)으로 부드러운 곡선 생성
    ///
    /// 연속된 두 점의 중점을 "곡선이 지나는 점"으로 사용하고,
    /// 원래 점을 제어점으로 쓰는 2차 베지어 곡선을 이어 붙입니다.
    /// 결과: C1 연속(접선 연속)의 부드러운 경로
    ///
    /// - move  → p[0]
    /// - quad  → to: mid(p[i], p[i+1]), control: p[i]   (i = 1 ..< n-1)
    /// - line  → p[last]
    private static func smoothPath(from points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard !points.isEmpty else { return path }

        // 점 한 개: 작은 원으로 표현 (점찍기)
        if points.count == 1 {
            let r: CGFloat = 2
            path.addEllipse(in: CGRect(
                x: points[0].x - r, y: points[0].y - r,
                width: r * 2,        height: r * 2
            ))
            return path
        }

        // 점 두 개: 직선
        if points.count == 2 {
            path.move(to: points[0])
            path.addLine(to: points[1])
            return path
        }

        // 점 세 개 이상: 2차 베지어 스무딩
        path.move(to: points[0])

        for i in 1..<points.count - 1 {
            let mid = CGPoint(
                x: (points[i].x + points[i + 1].x) / 2,
                y: (points[i].y + points[i + 1].y) / 2
            )
            path.addQuadCurve(to: mid, control: points[i])
        }

        path.addLine(to: points.last!)
        return path
    }
}
