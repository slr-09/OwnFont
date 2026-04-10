//
//  CharacterWritingViewController.swift
//  OwnFont
//

import UIKit
import PencilKit

final class CharacterWritingViewController: UIViewController {

    // MARK: - Properties
    private let category: CharacterCategory
    private var currentIndex: Int = 0
    private var completedIndices: Set<Int> = []

    private var contentView: CharacterWritingView {
        view as! CharacterWritingView
    }

    // MARK: - Init
    init(category: CharacterCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func loadView() {
        view = CharacterWritingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindCallbacks()
        contentView.setupCharSlots(characters: category.characters)
        refreshUI()
        setupPencilKit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // MARK: - Bind
    private func bindCallbacks() {
        contentView.onBackTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        contentView.onPenTap = { [weak self] in
            self?.contentView.setActiveTool(isPen: true)
            self?.contentView.canvasView.usePen()
        }
        contentView.onEraserTap = { [weak self] in
            self?.contentView.setActiveTool(isPen: false)
            self?.contentView.canvasView.useEraser()
        }
        contentView.onUndoTap = { [weak self] in
            self?.contentView.canvasView.undo()
        }
        contentView.onClearTap = { [weak self] in
            self?.contentView.canvasView.clearDrawing()
        }
        contentView.onNextTap = { [weak self] in
            self?.advanceToNextChar()
        }
    }

    // MARK: - PencilKit
    private func setupPencilKit() {
        contentView.canvasView.usePen()
    }

    // MARK: - Logic
    private func advanceToNextChar() {
        let total = category.characters.count
        guard currentIndex < total else { return }

        saveCurrentGlyph()
        completedIndices.insert(currentIndex)

        if let next = ((currentIndex + 1)..<total).first(where: { !completedIndices.contains($0) }) {
            currentIndex = next
        }

        contentView.canvasView.clearDrawing()
        refreshUI()
        contentView.scrollToSlot(at: currentIndex)
    }

    /// 현재 글자의 손글씨를 CGPath로 변환해 GlyphStore에 저장하고 미리보기를 표시
    private func saveCurrentGlyph() {
        let drawing = contentView.canvasView.drawing
        guard !drawing.strokes.isEmpty else { return }

        let character = category.characters[currentIndex]
        let canvasSize = contentView.canvasView.bounds.size

        let rawPath = DrawingPathExtractor.extract(from: drawing)
        let normalizedPath = GlyphNormalizer.normalize(rawPath, canvasSize: canvasSize)
        
        GlyphStore.shared.save(
            GlyphData(character: character, normalizedPath: normalizedPath, createdAt: Date())
        )

        // 복원 검증
        if let restored = GlyphStore.shared.glyph(for: character) {
            let box = restored.normalizedPath.boundingBoxOfPath
            print("복원 성공: \(character), boundingBox: \(box)")
        } else {
            print("복원 실패: \(character)")
        }
    }

    private func refreshUI() {
        let chars = category.characters
        guard currentIndex < chars.count else { return }

        contentView.updateCurrentChar(chars[currentIndex])
        contentView.updateCounter(current: currentIndex + 1, total: category.totalCount)
        contentView.updateSlots(currentIndex: currentIndex, completedIndices: completedIndices)
    }
}
