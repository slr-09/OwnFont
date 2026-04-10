//
//  CGPathTransformer.swift
//  OwnFont
//

import UIKit

/// CGPath ↔ Data 변환을 담당하는 NSValueTransformer
///
/// CoreData의 Transformable 속성에서 CGPath를 직접 저장하기 위해
/// UIBezierPath(NSSecureCoding 준수)를 중간 매개로 사용합니다.
///
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

    /// UIBezierPath → Data (저장 시)
    override func transformedValue(_ value: Any?) -> Any? {
        guard let bezier = value as? UIBezierPath else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: bezier, requiringSecureCoding: true)
    }

    /// Data → UIBezierPath (복원 시)
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: data)
    }
}
