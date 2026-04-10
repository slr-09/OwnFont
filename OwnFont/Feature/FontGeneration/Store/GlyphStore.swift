//
//  GlyphStore.swift
//  OwnFont
//

import CoreData
import CoreGraphics
import UIKit

/// 글리프 데이터 저장소 — CoreData 기반
final class GlyphStore {

    static let shared = GlyphStore()
    private init() {}

    private var context: NSManagedObjectContext { CoreDataStack.shared.context }

    // MARK: - Write

    /// 글리프를 저장합니다. 동일 character가 이미 존재하면 덮어씁니다.
    func save(_ glyph: GlyphData) {
        let entity = fetchEntity(for: glyph.character) ?? GlyphEntity(context: context)
        entity.character = glyph.character
        entity.pathData = UIBezierPath(cgPath: glyph.normalizedPath) as Any
        entity.createdAt = glyph.createdAt
        CoreDataStack.shared.save()
    }

    // MARK: - Read

    func glyph(for character: String) -> GlyphData? {
        fetchEntity(for: character).flatMap(toGlyphData)
    }

    func hasGlyph(for character: String) -> Bool {
        fetchEntity(for: character) != nil
    }

    var all: [String: GlyphData] {
        let request = NSFetchRequest<GlyphEntity>(entityName: "GlyphEntity")
        let entities = (try? context.fetch(request)) ?? []
        return entities.reduce(into: [:]) { dict, entity in
            if let glyph = toGlyphData(entity) {
                dict[entity.character] = glyph
            }
        }
    }

    // MARK: - Private

    private func fetchEntity(for character: String) -> GlyphEntity? {
        let request = NSFetchRequest<GlyphEntity>(entityName: "GlyphEntity")
        request.predicate = NSPredicate(format: "character == %@", character)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func toGlyphData(_ entity: GlyphEntity) -> GlyphData? {
        guard let bezier = entity.pathData as? UIBezierPath else { return nil }
        return GlyphData(character: entity.character, normalizedPath: bezier.cgPath, createdAt: entity.createdAt)
    }
}
