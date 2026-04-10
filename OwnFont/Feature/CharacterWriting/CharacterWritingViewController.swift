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
        contentView.canvasView.usePen()
        restoreCompletedIndices()
        refreshUI()
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
        contentView.onSlotTap = { [weak self] index in
            self?.navigateTo(index: index)
        }
    }

    // MARK: - Restore
    /// GlyphStore에 저장된 문자를 completedIndices에 반영하고
    /// currentIndex를 첫 번째 미완성 문자로 설정
    private func restoreCompletedIndices() {
        let chars = category.characters
        completedIndices = Set(
            chars.indices.filter { GlyphStore.shared.hasGlyph(for: chars[$0]) }
        )
        if let first = chars.indices.first(where: { !completedIndices.contains($0) }) {
            currentIndex = first
        }
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

        refreshUI()
        contentView.scrollToSlot(at: currentIndex)
    }

    /// 슬롯 탭 → 현재 글자 저장 후 해당 인덱스로 이동
    private func navigateTo(index: Int) {
        guard index != currentIndex, index < category.characters.count else { return }
        saveCurrentGlyph()
        currentIndex = index
        refreshUI()
        contentView.scrollToSlot(at: currentIndex)
    }

    /// CGPath + PKDrawing 모두 저장
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
        GlyphStore.shared.saveDrawing(drawing, for: character)
    }

    private func refreshUI() {
        let chars = category.characters
        guard currentIndex < chars.count else { return }

        contentView.updateCurrentChar(chars[currentIndex])
        contentView.updateCounter(current: currentIndex + 1, total: category.totalCount)
        contentView.updateSlots(currentIndex: currentIndex, completedIndices: completedIndices)

        // 저장된 드로잉 복원, 없으면 캔버스 초기화
        let character = chars[currentIndex]
        if let saved = GlyphStore.shared.loadDrawing(for: character) {
            contentView.canvasView.drawing = saved
        } else {
            contentView.canvasView.clearDrawing()
        }
    }
}
