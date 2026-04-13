//
//  GlyphStore.swift
//  OwnFont
//

import Combine
import CoreData
import CoreGraphics
import PencilKit
import UIKit

/// 글리프 데이터 저장소 — CoreData(CGPath) + 파일(PKDrawing)
final class GlyphStore {

    static let shared = GlyphStore()
    private init() {}

    let glyphsDidChange = PassthroughSubject<Void, Never>()

    private var context: NSManagedObjectContext { CoreDataStack.shared.context }

    // MARK: - Write

    /// 글리프를 저장합니다. 동일 character가 이미 존재하면 덮어씁니다.
    func save(_ glyph: GlyphData) {
        let entity = fetchEntity(for: glyph.character) ?? GlyphEntity(context: context)
        entity.character = glyph.character
        entity.pathData = UIBezierPath(cgPath: glyph.normalizedPath)
        entity.createdAt = glyph.createdAt
        CoreDataStack.shared.save()
        glyphsDidChange.send()
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

    // MARK: - PKDrawing (파일 기반)

    /// PKDrawing을 Documents 폴더에 바이너리 파일로 저장
    func saveDrawing(_ drawing: PKDrawing, for character: String) {
        let data = drawing.dataRepresentation()
        try? data.write(to: drawingURL(for: character), options: .atomic)
    }

    /// 저장된 PKDrawing 복원 (없으면 nil)
    func loadDrawing(for character: String) -> PKDrawing? {
        guard let data = try? Data(contentsOf: drawingURL(for: character)) else { return nil }
        return try? PKDrawing(data: data)
    }

    private func drawingURL(for character: String) -> URL {
        // 유니코드 코드포인트로 파일명 생성 (특수문자 안전 처리)
        let safe = character.unicodeScalars.map { "U\($0.value)" }.joined()
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("drawing_\(safe).bin")
    }

    // MARK: - Private

    private func fetchEntity(for character: String) -> GlyphEntity? {
        let request = NSFetchRequest<GlyphEntity>(entityName: "GlyphEntity")
        request.predicate = NSPredicate(format: "character == %@", character)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func toGlyphData(_ entity: GlyphEntity) -> GlyphData? {
        guard let bezier = entity.pathData else { return nil }
        return GlyphData(character: entity.character, normalizedPath: bezier.cgPath, createdAt: entity.createdAt)
    }
}
