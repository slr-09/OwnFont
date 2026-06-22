//
//  CharacterWritingViewController.swift
//  OwnFont
//

import Combine
import GoogleMobileAds
import UIKit
import PencilKit

final class CharacterWritingViewController: UIViewController {

    // MARK: - Properties
    private let category: CharacterCategory
    private var currentIndex: Int = 0
    private var completedIndices: Set<Int> = []
    private var cancellables = Set<AnyCancellable>()
    private var interstitial: InterstitialAd?

    /// 이번 방문에서 새로 쓴(저장한) 글자 인덱스. 전면 광고 노출 기준에 사용한다.
    private var sessionWrittenIndices: Set<Int> = []
    private static let adMinWriteCount = 5

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
        updateCrashContext(action: "view_did_load")
        bindCallbacks()
        contentView.setupCharSlots(characters: category.characters)
        contentView.canvasView.usePen()
        restoreCompletedIndices()
        refreshUI()
        if completedIndices.count < category.characters.count {
            loadInterstitialAd()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
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
                    navigationController?.popViewController(animated: true)
                case .penSelected:
                    updateCrashContext(action: "select_pen")
                    contentView.setActiveTool(isPen: true)
                    contentView.canvasView.usePen()
                case .eraserSelected:
                    updateCrashContext(action: "select_eraser")
                    contentView.setActiveTool(isPen: false)
                    contentView.canvasView.useEraser()
                case .undo:
                    updateCrashContext(action: "tap_undo")
                    contentView.canvasView.undo()
                case .clear:
                    updateCrashContext(action: "tap_clear")
                    contentView.canvasView.clearDrawing()
                case .next:
                    updateCrashContext(action: "tap_next")
                    advanceToNextChar()
                case .done:
                    updateCrashContext(action: "tap_done")
                    saveCurrentGlyph()
                    showInterstitialOrPop()
                case .save:
                    updateCrashContext(action: "tap_save")
                    saveAndCycleToNext()
                case .clearAll:
                    updateCrashContext(action: "tap_clear_all")
                    showClearAllConfirmation()
                case .slotTapped(let index):
                    updateCrashContext(action: "tap_slot_\(index)")
                    navigateTo(index: index)
                }
            }
            .store(in: &cancellables)
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
    /// 수정 모드: 현재 글자 저장 후 다음 슬롯으로 순환 이동 (화면 유지)
    private func saveAndCycleToNext() {
        saveCurrentGlyph()
        let total = category.characters.count
        guard total > 1 else { return }
        currentIndex = (currentIndex + 1) % total
        refreshUI()
        contentView.scrollToSlot(at: currentIndex)
    }

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

    /// CGPath + PKDrawing 모두 저장 (변경 없으면 스킵)
    private func saveCurrentGlyph() {
        let drawing = contentView.canvasView.drawing
        updateCrashContext(action: "save_current_glyph_start", strokeCount: drawing.strokes.count)
        guard !drawing.strokes.isEmpty else {
            updateCrashContext(action: "save_current_glyph_skip_empty", strokeCount: 0)
            return
        }

        let character = category.characters[currentIndex]
        if let saved = GlyphStore.shared.loadDrawing(for: character), saved == drawing {
            updateCrashContext(action: "save_current_glyph_skip_unchanged", strokeCount: drawing.strokes.count)
            return
        }

        let canvasSize = contentView.canvasView.bounds.size
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            updateCrashContext(action: "save_current_glyph_skip_invalid_canvas", strokeCount: drawing.strokes.count)
            return
        }

        let rawPath = DrawingPathExtractor.extract(from: drawing)
        let normalizedPath = GlyphNormalizer.normalize(rawPath, canvasSize: canvasSize)

        GlyphStore.shared.save(
            GlyphData(character: character, normalizedPath: normalizedPath, createdAt: Date())
        )
        GlyphStore.shared.saveDrawing(drawing, for: character)
        sessionWrittenIndices.insert(currentIndex)
        updateCrashContext(action: "save_current_glyph_finish", strokeCount: drawing.strokes.count)
    }

    // MARK: - Interstitial Ad

    private func loadInterstitialAd() {
        guard interstitial == nil else { return }
        guard let adUnitID = Bundle.main.object(forInfoDictionaryKey: "AdMobInterstitialID") as? String else { return }
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, _ in
            guard let self, let ad else { return }
            self.interstitial = ad
            ad.fullScreenContentDelegate = self
        }
    }

    private func showInterstitialOrPop() {
        if sessionWrittenIndices.count >= Self.adMinWriteCount, let ad = interstitial {
            updateCrashContext(action: "present_interstitial")
            interstitial = nil
            ad.present(from: self)
        } else {
            updateCrashContext(action: "pop_without_interstitial")
            navigationController?.popViewController(animated: true)
        }
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
            sessionWrittenIndices.removeAll()
            currentIndex = 0
            updateCrashContext(action: "clear_all_confirmed")
            refreshUI()
            loadInterstitialAd()
        })
        alert.addAction(UIAlertAction(title: L.buttonCancel, style: .cancel))
        presentAlert(alert)
    }

    private func refreshUI() {
        let chars = category.characters
        guard currentIndex < chars.count else { return }
        updateCrashContext(action: "refresh_ui")

        contentView.updateCurrentChar(chars[currentIndex])
        contentView.updateCounter(current: currentIndex + 1, total: category.totalCount)
        contentView.updateSlots(currentIndex: currentIndex, completedIndices: completedIndices)
        contentView.updateProgress(completed: completedIndices.count, total: chars.count)

        let isAlreadyCompleted = completedIndices.contains(currentIndex)
        let hasMoreUncompleted = chars.indices.contains(where: { !completedIndices.contains($0) && $0 != currentIndex })
        let mode: CharacterWritingView.NextButtonMode
        if isAlreadyCompleted {
            mode = .save                          // 이미 완성된 글자 수정 중
        } else if !hasMoreUncompleted {
            mode = .done                          // 마지막 미완성 글자
        } else {
            mode = .next                          // 미완성 글자가 더 있음
        }
        contentView.updateNextButton(mode: mode)

        // 저장된 드로잉 복원, 없으면 캔버스 초기화
        let character = chars[currentIndex]
        if let saved = GlyphStore.shared.loadDrawing(for: character) {
            contentView.canvasView.drawing = saved
        } else {
            contentView.canvasView.clearDrawing()
        }
    }

    private func updateCrashContext(action: String, strokeCount: Int? = nil) {
        let chars = category.characters
        let character = chars.indices.contains(currentIndex) ? chars[currentIndex] : nil
        AnalyticsManager.shared.setWritingCrashContext(
            screen: "character_writing",
            category: category,
            index: currentIndex,
            character: character,
            action: action,
            strokeCount: strokeCount
        )
    }
}

// MARK: - FullScreenContentDelegate

extension CharacterWritingViewController: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        updateCrashContext(action: "interstitial_dismissed")
        navigationController?.popViewController(animated: true)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        updateCrashContext(action: "interstitial_failed_to_present")
        navigationController?.popViewController(animated: true)
    }
}
