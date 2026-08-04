//
//  CharacterWritingGridViewController.swift
//  OwnFont
//

import Combine
import UIKit
import PencilKit

final class CharacterWritingGridViewController: UIViewController,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties
    private let category: CharacterCategory
    private var focusedIndex: Int?
    private var completedIndices: Set<Int> = []
    private var isPen: Bool = true
    private var cancellables = Set<AnyCancellable>()

    private var contentView: CharacterWritingGridView {
        view as! CharacterWritingGridView
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
        view = CharacterWritingGridView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateCrashContext(action: "view_did_load")
        contentView.collectionView.dataSource = self
        contentView.collectionView.delegate = self
        bindCallbacks()
        restoreCompletedIndices()
        refreshProgress()
        InterstitialAdGate.shared.preload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.contentView.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    // MARK: - Bind
    private func bindCallbacks() {
        contentView.actionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .back:
                    updateCrashContext(action: "tap_back")
                    showInterstitialOrPop()
                case .clearAll:
                    updateCrashContext(action: "tap_clear_all")
                    showClearAllConfirmation()
                case .penSelected:
                    updateCrashContext(action: "select_pen")
                    isPen = true
                    contentView.setActiveTool(isPen: true)
                    applyToolToFocusedCell()
                case .eraserSelected:
                    updateCrashContext(action: "select_eraser")
                    isPen = false
                    contentView.setActiveTool(isPen: false)
                    applyToolToFocusedCell()
                case .undo:
                    updateCrashContext(action: "tap_undo")
                    focusedCell()?.canvasContainer.undo()
                case .clear:
                    updateCrashContext(action: "tap_clear")
                    clearFocusedCell()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Restore
    private func restoreCompletedIndices() {
        let chars = category.characters
        completedIndices = Set(
            chars.indices.filter { GlyphStore.shared.hasGlyph(for: chars[$0]) }
        )
    }

    // MARK: - Helpers
    private func focusedCell() -> CharacterWritingGridCell? {
        guard let idx = focusedIndex else { return nil }
        return contentView.collectionView
            .cellForItem(at: IndexPath(item: idx, section: 0)) as? CharacterWritingGridCell
    }

    private func applyToolToFocusedCell() {
        guard let cell = focusedCell() else { return }
        if isPen { cell.canvasContainer.usePen() } else { cell.canvasContainer.useEraser() }
    }

    private func setFocused(at index: Int) {
        if focusedIndex == index { return }
        updateCrashContext(action: "focus_cell_\(index)", index: index)
        if let prev = focusedIndex,
           let prevCell = contentView.collectionView
               .cellForItem(at: IndexPath(item: prev, section: 0)) as? CharacterWritingGridCell {
            prevCell.setFocused(false)
        }
        focusedIndex = index
        if let cell = contentView.collectionView
            .cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterWritingGridCell {
            cell.setFocused(true)
            if isPen { cell.canvasContainer.usePen() } else { cell.canvasContainer.useEraser() }
        }
    }

    private func clearFocusedCell() {
        guard let idx = focusedIndex, let cell = focusedCell() else { return }
        updateCrashContext(action: "clear_focused_cell", index: idx, strokeCount: cell.canvasContainer.drawing.strokes.count)
        cell.canvasContainer.clearDrawing()
        let character = category.characters[idx]
        GlyphStore.shared.deleteAllGlyphs(for: [character])
        if completedIndices.remove(idx) != nil {
            cell.setCompleted(false)
            refreshProgress()
        }
    }

    private func saveGlyph(at index: Int, drawing: PKDrawing) {
        updateCrashContext(action: "save_glyph_start", index: index, strokeCount: drawing.strokes.count)
        let chars = category.characters
        guard index < chars.count else { return }
        let character = chars[index]

        if drawing.strokes.isEmpty {
            if completedIndices.remove(index) != nil {
                GlyphStore.shared.deleteAllGlyphs(for: [character])
                if let cell = contentView.collectionView
                    .cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterWritingGridCell {
                    cell.setCompleted(false)
                }
                refreshProgress()
            }
            updateCrashContext(action: "save_glyph_empty", index: index, strokeCount: 0)
            return
        }

        if let saved = GlyphStore.shared.loadDrawing(for: character), saved == drawing {
            updateCrashContext(action: "save_glyph_skip_unchanged", index: index, strokeCount: drawing.strokes.count)
            return
        }

        let canvasSize: CGSize = {
            if let cell = contentView.collectionView
                .cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterWritingGridCell {
                return cell.canvasContainer.bounds.size
            }
            return .zero
        }()
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            updateCrashContext(action: "save_glyph_skip_invalid_canvas", index: index, strokeCount: drawing.strokes.count)
            return
        }

        let rawPath = DrawingPathExtractor.extract(from: drawing)
        let normalizedPath = GlyphNormalizer.normalize(rawPath, canvasSize: canvasSize)

        GlyphStore.shared.save(
            GlyphData(character: character, normalizedPath: normalizedPath, createdAt: Date())
        )
        GlyphStore.shared.saveDrawing(drawing, for: character)
        InterstitialAdGate.shared.recordWrite()

        if completedIndices.insert(index).inserted {
            if let cell = contentView.collectionView
                .cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterWritingGridCell {
                cell.setCompleted(true)
            }
            refreshProgress()
        }
        updateCrashContext(action: "save_glyph_finish", index: index, strokeCount: drawing.strokes.count)
    }

    // MARK: - Interstitial Ad

    private func showInterstitialOrPop() {
        let didPresent = InterstitialAdGate.shared.presentIfEligible(from: self) { [weak self] in
            guard let self else { return }
            updateCrashContext(action: "interstitial_dismissed")
            navigationController?.popViewController(animated: true)
        }
        if didPresent {
            updateCrashContext(action: "present_interstitial")
        } else {
            updateCrashContext(action: "pop_without_interstitial")
            navigationController?.popViewController(animated: true)
        }
    }

    private func refreshProgress() {
        contentView.updateCounter(current: completedIndices.count, total: category.totalCount)
        contentView.updateProgress(completed: completedIndices.count, total: category.characters.count)
    }

    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: L.alertClearAllTitle(category.title),
            message: L.alertClearAllMessage(category.title),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L.buttonDelete, style: .destructive) { [weak self] _ in
            guard let self else { return }
            GlyphStore.shared.deleteAllGlyphs(for: category.characters)
            completedIndices.removeAll()
            updateCrashContext(action: "clear_all_confirmed")
            contentView.collectionView.visibleCells.forEach { cell in
                guard let c = cell as? CharacterWritingGridCell else { return }
                c.canvasContainer.clearDrawing()
                c.setCompleted(false)
            }
            refreshProgress()
        })
        alert.addAction(UIAlertAction(title: L.buttonCancel, style: .cancel))
        presentAlert(alert)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        category.characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CharacterWritingGridCell.reuseID,
            for: indexPath
        ) as! CharacterWritingGridCell

        let index = indexPath.item
        let character = category.characters[index]
        let drawing = GlyphStore.shared.loadDrawing(for: character)

        cell.configure(
            character: character,
            drawing: drawing,
            isCompleted: completedIndices.contains(index),
            isFocused: focusedIndex == index
        )
        if isPen { cell.canvasContainer.usePen() } else { cell.canvasContainer.useEraser() }

        cell.onFocusRequest = { [weak self, weak cell] in
            guard let self, let cell,
                  let idx = collectionView.indexPath(for: cell)?.item else { return }
            setFocused(at: idx)
        }
        cell.onDrawingChanged = { [weak self, weak cell] drawing in
            guard let self, let cell,
                  let idx = collectionView.indexPath(for: cell)?.item else { return }
            saveGlyph(at: idx, drawing: drawing)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    // 모든 방향에서 셀 크기를 동일하게 유지(저장된 드로잉이 동일 픽셀로 렌더)
    private static let fixedCellSide: CGFloat = 140
    private static let cellSpacing: CGFloat = 12
    private static let minSideInset: CGFloat = 20

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Self.fixedCellSide, height: Self.fixedCellSide)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let width = collectionView.bounds.width
        let side = Self.fixedCellSide
        let spacing = Self.cellSpacing
        let minInset = Self.minSideInset

        let usable = width - minInset * 2 + spacing
        let columns = max(1, floor(usable / (side + spacing)))
        let usedWidth = columns * side + (columns - 1) * spacing
        let sideInset = max(minInset, floor((width - usedWidth) / 2))
        return UIEdgeInsets(top: 12, left: sideInset, bottom: 12, right: sideInset)
    }

    private func updateCrashContext(action: String, index: Int? = nil, strokeCount: Int? = nil) {
        let chars = category.characters
        let targetIndex = index ?? focusedIndex
        let character: String?
        if let targetIndex, chars.indices.contains(targetIndex) {
            character = chars[targetIndex]
        } else {
            character = nil
        }
        AnalyticsManager.shared.setWritingCrashContext(
            screen: "character_writing_grid",
            category: category,
            index: targetIndex,
            character: character,
            action: action,
            strokeCount: strokeCount
        )
    }
}
