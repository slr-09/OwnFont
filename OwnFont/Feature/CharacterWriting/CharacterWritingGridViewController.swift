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
        contentView.collectionView.dataSource = self
        contentView.collectionView.delegate = self
        bindCallbacks()
        restoreCompletedIndices()
        refreshCounter()
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
                    navigationController?.popViewController(animated: true)
                case .clearAll:
                    showClearAllConfirmation()
                case .penSelected:
                    isPen = true
                    contentView.setActiveTool(isPen: true)
                    applyToolToFocusedCell()
                case .eraserSelected:
                    isPen = false
                    contentView.setActiveTool(isPen: false)
                    applyToolToFocusedCell()
                case .undo:
                    focusedCell()?.canvasContainer.undo()
                case .clear:
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
        cell.canvasContainer.clearDrawing()
        let character = category.characters[idx]
        GlyphStore.shared.deleteAllGlyphs(for: [character])
        if completedIndices.remove(idx) != nil {
            cell.setCompleted(false)
            refreshCounter()
        }
    }

    private func saveGlyph(at index: Int, drawing: PKDrawing) {
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
                refreshCounter()
            }
            return
        }

        if let saved = GlyphStore.shared.loadDrawing(for: character), saved == drawing { return }

        let canvasSize: CGSize = {
            if let cell = contentView.collectionView
                .cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterWritingGridCell {
                return cell.canvasContainer.bounds.size
            }
            return .zero
        }()

        let rawPath = DrawingPathExtractor.extract(from: drawing)
        let normalizedPath = GlyphNormalizer.normalize(rawPath, canvasSize: canvasSize)

        GlyphStore.shared.save(
            GlyphData(character: character, normalizedPath: normalizedPath, createdAt: Date())
        )
        GlyphStore.shared.saveDrawing(drawing, for: character)

        if completedIndices.insert(index).inserted {
            if let cell = contentView.collectionView
                .cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterWritingGridCell {
                cell.setCompleted(true)
            }
            refreshCounter()
        }
    }

    private func refreshCounter() {
        contentView.updateCounter(current: completedIndices.count, total: category.totalCount)
    }

    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: "\(category.title) 전체 삭제",
            message: "저장된 \(category.title) 글자가 모두 삭제됩니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            GlyphStore.shared.deleteAllGlyphs(for: category.characters)
            completedIndices.removeAll()
            contentView.collectionView.visibleCells.forEach { cell in
                guard let c = cell as? CharacterWritingGridCell else { return }
                c.canvasContainer.clearDrawing()
                c.setCompleted(false)
            }
            refreshCounter()
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
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
}
