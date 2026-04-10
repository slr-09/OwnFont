//
//  GlyphData.swift
//  OwnFont
//

import CoreGraphics
import Foundation

/// 한 글자의 손글씨 벡터 데이터 (런타임 모델)
struct GlyphData {
    /// 해당 글리프가 표현하는 문자 (예: "A", "1")
    let character: String

    /// 정규화된 CGPath — Em Square (0,0)~(1000,1000) 좌표계
    /// - origin: 좌하단 (폰트 관례, Y↑)
    /// - baseline: y = 150 (하단 15% descender 영역)
    let normalizedPath: CGPath

    let createdAt: Date
}
