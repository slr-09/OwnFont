//
//  CharacterWritingView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class CharacterWritingView: UIView {

    // MARK: - Types
    enum NextButtonMode { case next, done, save }

    // MARK: - Callbacks
    var onBackTap: (() -> Void)?
    var onNextTap: (() -> Void)?
    var onDoneTap: (() -> Void)?
    var onSaveTap: (() -> Void)?
    var onPenTap: (() -> Void)?
    var onEraserTap: (() -> Void)?
    var onUndoTap: (() -> Void)?
    var onClearTap: (() -> Void)?
    var onSlotTap: ((Int) -> Void)?

    // MARK: - Nav Bar
    private let navBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .surface
        return v
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .surfaceSecondary
        btn.layer.cornerRadius = 18
        btn.tintColor = .textPrimary
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        return btn
    }()

    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "글자 쓰기"
        l.font = .cardHeader
        l.textColor = .textPrimary
        return l
    }()

    private let counterBadge: UIView = {
        let v = UIView()
        v.backgroundColor = .indigoLight
        v.layer.cornerRadius = 12
        return v
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.font = .caption
        l.textColor = .indigo
        return l
    }()

    // MARK: - Char Grid
    private let charGridLabel: UILabel = {
        let l = UILabel()
        l.text = "완성된 글자"
        l.font = .caption
        l.textColor = .textHint
        return l
    }()

    private let charScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let charStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        return sv
    }()

    private var charSlotButtons: [UIButton] = []
    private var nextButtonMode: NextButtonMode = .next

    // MARK: - Current Char
    private let currentCharRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    private let currentCharHintLabel: UILabel = {
        let l = UILabel()
        l.text = "현재 글자:"
        l.font = .subLabel
        l.textColor = .textHint
        return l
    }()

    private let currentCharBigLabel: UILabel = {
        let l = UILabel()
        l.font = .custom(size: 22)
        l.textColor = .primary
        return l
    }()

    // MARK: - Canvas
    let canvasView = CharacterCanvasView()

    // 캔버스 상하 여백을 균등하게 분배하기 위한 스페이서
    private let topCanvasSpacer = UIView()
    private let bottomCanvasSpacer = UIView()

    // MARK: - Tool Bar
    private let toolBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .surface
        return v
    }()

    private lazy var penButton = makeToolButton(iconName: "pencil", isActive: true)
    private lazy var eraserButton = makeToolButton(iconName: "eraser")
    private lazy var undoButton = makeToolButton(iconName: "arrow.uturn.backward")
    private lazy var clearButton = makeToolButton(iconName: "trash")

    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .primary
        btn.layer.cornerRadius = 20
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            "다음 글자",
            attributes: AttributeContainer([
                .font: UIFont.body,
                .foregroundColor: UIColor.white
            ])
        )
        config.image = UIImage(systemName: "chevron.right")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        config.baseForegroundColor = .white
        btn.configuration = config
        return btn
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupLayout() {
        addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(navTitleLabel)
        navBarView.addSubview(counterBadge)
        counterBadge.addSubview(counterLabel)

        addSubview(charGridLabel)
        addSubview(charScrollView)
        charScrollView.addSubview(charStackView)

        currentCharRow.addArrangedSubview(currentCharHintLabel)
        currentCharRow.addArrangedSubview(currentCharBigLabel)
        addSubview(currentCharRow)

        addSubview(topCanvasSpacer)
        addSubview(canvasView)
        addSubview(bottomCanvasSpacer)

        addSubview(toolBarView)
        let toolsStack = UIStackView(arrangedSubviews: [penButton, eraserButton, undoButton, clearButton])
        toolsStack.spacing = 8
        toolBarView.addSubview(toolsStack)
        toolBarView.addSubview(nextButton)

        navBarView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(52)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        counterBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        counterLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }

        charGridLabel.snp.makeConstraints { make in
            make.top.equalTo(navBarView.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(20)
        }
        charScrollView.snp.makeConstraints { make in
            make.top.equalTo(charGridLabel.snp.bottom).offset(6)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(36)
        }
        charStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview()
            make.height.equalTo(charScrollView)
        }

        currentCharRow.snp.makeConstraints { make in
            make.top.equalTo(charScrollView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        toolsStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview().inset(16)
        }
        [penButton, eraserButton, undoButton, clearButton].forEach { btn in
            btn.snp.makeConstraints { make in make.size.equalTo(48) }
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: 툴바 하단 고정, 캔버스는 남은 공간에서 상하 균등 배치
            toolBarView.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            }
            topCanvasSpacer.snp.makeConstraints { make in
                make.top.equalTo(currentCharRow.snp.bottom)
                make.bottom.equalTo(canvasView.snp.top)
                make.horizontalEdges.equalToSuperview()
                make.height.greaterThanOrEqualTo(8)
            }
            canvasView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(220)
                make.width.equalToSuperview().inset(100).priority(.high)
                make.height.equalTo(canvasView.snp.width)
            }
            bottomCanvasSpacer.snp.makeConstraints { make in
                make.top.equalTo(canvasView.snp.bottom)
                make.bottom.equalTo(toolBarView.snp.top)
                make.horizontalEdges.equalToSuperview()
                make.height.greaterThanOrEqualTo(8)
                make.height.equalTo(topCanvasSpacer)
            }
        } else {
            // iPhone: 캔버스 바로 아래에 툴바 배치 (기존 동작)
            canvasView.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview().inset(100)
                make.top.equalTo(currentCharRow.snp.bottom).offset(16)
                make.height.equalTo(canvasView.snp.width)
            }
            toolBarView.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview()
                make.top.equalTo(canvasView.snp.bottom).offset(16)
            }
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        penButton.addTarget(self, action: #selector(handlePen), for: .touchUpInside)
        eraserButton.addTarget(self, action: #selector(handleEraser), for: .touchUpInside)
        undoButton.addTarget(self, action: #selector(handleUndo), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
    }

    @objc private func handleBack()   { onBackTap?() }
    @objc private func handlePen()    { onPenTap?() }
    @objc private func handleEraser() { onEraserTap?() }
    @objc private func handleUndo()   { onUndoTap?() }
    @objc private func handleClear()  { onClearTap?() }
    @objc private func handleNext() {
        switch nextButtonMode {
        case .next: onNextTap?()
        case .done: onDoneTap?()
        case .save: onSaveTap?()
        }
    }
    @objc private func slotTapped(_ sender: UIButton) { onSlotTap?(sender.tag) }

    // MARK: - Public Interface
    func setupCharSlots(characters: [String]) {
        charSlotButtons.forEach { $0.removeFromSuperview() }
        charSlotButtons = []

        characters.enumerated().forEach { index, char in
            let btn = UIButton(type: .custom)
            btn.setTitle(char, for: .normal)
            btn.titleLabel?.font = .body
            btn.layer.cornerRadius = 10
            btn.tag = index
            btn.addTarget(self, action: #selector(slotTapped(_:)), for: .touchUpInside)
            btn.snp.makeConstraints { make in make.size.equalTo(36) }
            charStackView.addArrangedSubview(btn)
            charSlotButtons.append(btn)
        }
    }

    func updateSlots(currentIndex: Int, completedIndices: Set<Int>) {
        charSlotButtons.enumerated().forEach { index, btn in
            let isCompleted = completedIndices.contains(index)
            let isCurrent   = index == currentIndex

            if isCompleted && isCurrent {
                // 완성된 글자 수정 중: 색 반전(흰 배경 + primary 텍스트)으로 구분
                btn.backgroundColor = .surface
                btn.setTitleColor(.primary, for: .normal)
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = UIColor.primary.cgColor
            } else if isCompleted {
                btn.backgroundColor = .primary
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderWidth = 0
            } else if isCurrent {
                btn.backgroundColor = .amberLight
                btn.setTitleColor(.amberDark, for: .normal)
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = UIColor.amberBorder.cgColor
            } else {
                btn.backgroundColor = .surfaceSecondary
                btn.setTitleColor(.borderLight, for: .normal)
                btn.layer.borderWidth = 0
                btn.layer.borderColor = UIColor.amberBorder.cgColor  // amber 상태에서 전환 시 carryover 방지
            }
        }
    }

    func updateCurrentChar(_ char: String) {
        currentCharBigLabel.text = char
        canvasView.setGuideChar(char)
    }

    func updateCounter(current: Int, total: Int) {
        counterLabel.text = "\(current) / \(total)"
    }

    func scrollToSlot(at index: Int) {
        guard index < charSlotButtons.count else { return }
        layoutIfNeeded()
        let btn = charSlotButtons[index]
        let btnFrame = charStackView.convert(btn.frame, to: charScrollView)
        let targetX = max(0, btnFrame.midX - charScrollView.bounds.width / 2)
        charScrollView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
    }

    func updateNextButton(mode: NextButtonMode) {
        nextButtonMode = mode
        var config = nextButton.configuration ?? UIButton.Configuration.plain()
        let titleAttrs = AttributeContainer([
            .font: UIFont.body,
            .foregroundColor: UIColor.white
        ])
        let symCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        switch mode {
        case .next:
            config.attributedTitle = AttributedString("다음 글자", attributes: titleAttrs)
            config.image = UIImage(systemName: "chevron.right", withConfiguration: symCfg)
        case .done:
            config.attributedTitle = AttributedString("완료", attributes: titleAttrs)
            config.image = UIImage(systemName: "checkmark", withConfiguration: symCfg)
        case .save:
            config.attributedTitle = AttributedString("저장", attributes: titleAttrs)
            config.image = UIImage(systemName: "square.and.arrow.down", withConfiguration: symCfg)
        }
        nextButton.configuration = config
    }

    func setActiveTool(isPen: Bool) {
        penButton.backgroundColor = isPen ? .primary : .surfaceSecondary
        penButton.tintColor = isPen ? .white : .iconInactive
        eraserButton.backgroundColor = isPen ? .surfaceSecondary : .primary
        eraserButton.tintColor = isPen ? .iconInactive : .white
    }

    // MARK: - Helper
    private func makeToolButton(iconName: String, isActive: Bool = false) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = isActive ? .primary : .surfaceSecondary
        btn.layer.cornerRadius = 16
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: iconName, withConfiguration: cfg), for: .normal)
        btn.tintColor = isActive ? .white : .iconInactive
        return btn
    }
}
