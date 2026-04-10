//
//  CGPathTransformer.swift
//  OwnFont
//

import UIKit

/// CGPath ↔ Data 변환을 담당하는 NSValueTransformer
///
/// NSSecureUnarchiveFromDataTransformer의 방향:
///   - transformedValue      : Data → Object  (디스크 읽기)
///   - reverseTransformedValue: Object → Data  (디스크 쓰기)
///
/// allowedTopLevelClasses 만 지정하면 베이스 클래스가 양방향을 올바르게 처리합니다.
/// 등록: AppDelegate에서 `CGPathTransformer.register()` 호출 필수
/// (NSPersistentContainer 로드 이전에 등록되어야 함)
@objc(CGPathTransformer)
final class CGPathTransformer: NSSecureUnarchiveFromDataTransformer {

    override class var allowedTopLevelClasses: [AnyClass] {
        [UIBezierPath.self]
    }

    static func register() {
        let name = NSValueTransformerName("CGPathTransformer")
        ValueTransformer.setValueTransformer(CGPathTransformer(), forName: name)
    }
}
