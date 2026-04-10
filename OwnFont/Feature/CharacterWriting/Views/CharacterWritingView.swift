//
//  CharacterWritingView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class CharacterWritingView: UIView {

    // MARK: - Callbacks
    var onBackTap: (() -> Void)?
    var onNextTap: (() -> Void)?
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
        l.font = .systemFont(ofSize: 17, weight: .bold)
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
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .indigo
        return l
    }()

    // MARK: - Char Grid
    private let charGridLabel: UILabel = {
        let l = UILabel()
        l.text = "완성된 글자"
        l.font = .systemFont(ofSize: 12, weight: .medium)
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
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .textHint
        return l
    }()

    private let currentCharBigLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .heavy)
        l.textColor = .primary
        return l
    }()

    // MARK: - Canvas
    let canvasView = CharacterCanvasView()

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
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
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

        addSubview(canvasView)

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

        toolBarView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(canvasView.snp.bottom).offset(16)
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

        canvasView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(50)
            make.top.equalTo(currentCharRow.snp.bottom).offset(16)
            make.height.equalTo(canvasView.snp.width)   // 정사각형 비율 유지
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
    @objc private func handleNext()   { onNextTap?() }
    @objc private func slotTapped(_ sender: UIButton) { onSlotTap?(sender.tag) }

    // MARK: - Public Interface
    func setupCharSlots(characters: [String]) {
        charSlotButtons.forEach { $0.removeFromSuperview() }
        charSlotButtons = []

        characters.enumerated().forEach { index, char in
            let btn = UIButton(type: .custom)
            btn.setTitle(char, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
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
            if completedIndices.contains(index) {
                btn.backgroundColor = .primary
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderWidth = 0
            } else if index == currentIndex {
                btn.backgroundColor = .amberLight
                btn.setTitleColor(.amberDark, for: .normal)
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = UIColor.amberBorder.cgColor
            } else {
                btn.backgroundColor = .surfaceSecondary
                btn.setTitleColor(.borderLight, for: .normal)
                btn.layer.borderWidth = 0
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
