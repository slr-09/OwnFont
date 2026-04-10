//
//  GlyphEntity.swift
//  OwnFont
//

import CoreData
import UIKit

/// GlyphData의 CoreData 영속 엔티티
///
/// Codegen을 Manual/None으로 설정했기 때문에 직접 정의합니다.
/// pathData는 CGPathTransformer를 통해 UIBezierPath로 복원됩니다.
@objc(GlyphEntity)
final class GlyphEntity: NSManagedObject {
    @NSManaged var character: String
    @NSManaged var pathData: UIBezierPath?    // Transformable → CGPathTransformer 사용 (구체 타입 필수)
    @NSManaged var createdAt: Date
}
