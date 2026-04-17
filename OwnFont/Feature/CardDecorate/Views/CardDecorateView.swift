//
//  CardDecorateView.swift
//  OwnFont
//

import Combine
import UIKit
import SnapKit

final class CardDecorateView: UIView {

    // MARK: - Types

    enum Action {
        case back
        case saveImage
        case mainTextChanged(String)
        case subTextChanged(String)
        case backgroundColorSelected(bg: UIColor, stroke: UIColor)
        case textColorSelected(UIColor)
        case mainTextToggled(Bool)   // true = 보이기
        case subTextToggled(Bool)
    }

    // MARK: - Publisher

    let actionPublisher = PassthroughSubject<Action, Never>()

    // MARK: - Nav Bar

    private let navBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
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

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "카드 꾸미기"
        l.font = .cardHeader
        l.textColor = .textPrimary
        return l
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .primary
        btn.layer.cornerRadius = 16
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            "저장",
            attributes: AttributeContainer([
                .font: UIFont.body,
                .foregroundColor: UIColor.white
            ])
        )
        config.image = UIImage(systemName: "square.and.arrow.down")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.baseForegroundColor = .white
        btn.configuration = config
        return btn
    }()

    // MARK: - Card Preview

    private let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .background
        return v
    }()

    let memoCardView = MemoCardView()

    // MARK: - Bottom Panel

    private let bottomPanel: UIView = {
        let v = UIView()
        v.backgroundColor = .surface
        v.layer.cornerRadius = 24
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["텍스트", "색상"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .primary
        let normalAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.body,
            .foregroundColor: UIColor.textSecondary
        ]
        let selectedAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.body,
            .foregroundColor: UIColor.white
        ]
        sc.setTitleTextAttributes(normalAttr, for: .normal)
        sc.setTitleTextAttributes(selectedAttr, for: .selected)
        return sc
    }()

    // MARK: - Text Tab

    private let textTabView = UIView()

    private let mainTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "메인 텍스트를 입력하세요"
        tf.font = .cardHeader
        tf.textColor = .textPrimary
        tf.borderStyle = .none
        tf.backgroundColor = .background
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    private let subTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "서브 텍스트를 입력하세요"
        tf.font = .body
        tf.textColor = .textSecondary
        tf.borderStyle = .none
        tf.backgroundColor = .background
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    private let mainToggleButton: UIButton = makeToggleButton()
    private let subToggleButton: UIButton = makeToggleButton()

    private var isMainVisible = true
    private var isSubVisible = true
    private let feedbackGenerator = UINotificationFeedbackGenerator()

    // MARK: - Color Tab

    private let colorTabView = UIView()

    private static let bgColors: [(name: String, bg: UIColor, stroke: UIColor)] = [
        ("노랑",   UIColor(hex: "FFFBEB"), UIColor(hex: "FCD34D")),
        ("핑크",   UIColor(hex: "FFF0F0"), UIColor(hex: "FFAAB5")),
        ("민트",   UIColor(hex: "F0FFF4"), UIColor(hex: "6EE7B7")),
        ("라벤더", UIColor(hex: "F0F4FF"), UIColor(hex: "A5B4FC")),
        ("피치",   UIColor(hex: "FFF8F0"), UIColor(hex: "FDBA74")),
        ("흰색",   UIColor(hex: "FFFFFF"), UIColor(hex: "D0D0D0")),
    ]

    private var colorButtons: [UIButton] = []
    private var selectedColorIndex: Int = 0

    private static let textColors: [(name: String, color: UIColor)] = [
        ("검정",   UIColor(hex: "1A1A1A")),
        ("회색",   UIColor(hex: "6B7280")),
        ("흰색",   UIColor(hex: "FFFFFF")),
        ("네이비", UIColor(hex: "1E3A5F")),
        ("브라운", UIColor(hex: "7C4A1E")),
        ("포레스트", UIColor(hex: "1A4731")),
    ]

    private var textColorButtons: [UIButton] = []
    private var selectedTextColorIndex: Int = 0

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .background
        setupLayout()
        setupActions()
        setupTextFields()
        showTab(index: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(saveButton)

        addSubview(cardContainer)
        cardContainer.addSubview(memoCardView)

        addSubview(bottomPanel)
        bottomPanel.addSubview(segmentControl)
        bottomPanel.addSubview(textTabView)
        bottomPanel.addSubview(colorTabView)

        setupTextTab()
        setupColorTab()

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
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        bottomPanel.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(320)
        }
        segmentControl.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        textTabView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
        colorTabView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }

        cardContainer.snp.makeConstraints { make in
            make.top.equalTo(navBarView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(bottomPanel.snp.top)
        }
        memoCardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(24)
        }
    }

    private func setupTextTab() {
        let mainRow = makeTextRow(field: mainTextField, toggle: mainToggleButton)
        let subRow  = makeTextRow(field: subTextField,  toggle: subToggleButton)

        let stack = UIStackView(arrangedSubviews: [mainRow, subRow])
        stack.axis = .vertical
        stack.spacing = 10
        textTabView.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func makeTextRow(field: UITextField, toggle: UIButton) -> UIView {
        let row = UIView()
        row.addSubview(field)
        row.addSubview(toggle)
        field.snp.makeConstraints { make in
            make.leading.verticalEdges.equalToSuperview()
            make.trailing.equalTo(toggle.snp.leading).offset(-8)
            make.height.equalTo(44)
        }
        toggle.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        return row
    }

    private func setupColorTab() {
        // 배경색 섹션
        let bgLabel = makeSectionLabel("배경색")
        let bgStack = makeColorButtonStack()
        CardDecorateView.bgColors.enumerated().forEach { index, item in
            let btn = makeCircleButton(color: item.bg, selected: index == 0)
            btn.tag = index
            btn.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            bgStack.addArrangedSubview(btn)
            colorButtons.append(btn)
        }

        // 글자색 섹션
        let textColorLabel = makeSectionLabel("글자색")
        let textColorStack = makeColorButtonStack()
        CardDecorateView.textColors.enumerated().forEach { index, item in
            let btn = makeCircleButton(color: item.color, selected: index == 0)
            btn.tag = index
            btn.addTarget(self, action: #selector(textColorButtonTapped(_:)), for: .touchUpInside)
            textColorStack.addArrangedSubview(btn)
            textColorButtons.append(btn)
        }

        let outerStack = UIStackView(arrangedSubviews: [bgLabel, bgStack, textColorLabel, textColorStack])
        outerStack.axis = .vertical
        outerStack.spacing = 8
        outerStack.setCustomSpacing(4, after: bgLabel)
        outerStack.setCustomSpacing(16, after: bgStack)
        outerStack.setCustomSpacing(4, after: textColorLabel)
        colorTabView.addSubview(outerStack)

        let count = CardDecorateView.bgColors.count
        bgStack.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(44 * count + 12 * (count - 1))
            make.centerX.equalTo(outerStack)
        }
        let tcount = CardDecorateView.textColors.count
        textColorStack.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(44 * tcount + 12 * (tcount - 1))
            make.centerX.equalTo(outerStack)
        }
        outerStack.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .badge
        l.textColor = .textSecondary
        return l
    }

    private func makeColorButtonStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }

    private func makeCircleButton(color: UIColor, selected: Bool) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 22
        btn.layer.borderWidth = selected ? 2.5 : 1
        btn.layer.borderColor = selected ? UIColor.primary.cgColor : UIColor.border.cgColor

        // 밝은 색상 버튼에 안쪽 그림자 추가 (배경과 구분)
        var white: CGFloat = 0
        color.getWhite(&white, alpha: nil)
        if white > 0.9 {
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOpacity = 0.1
            btn.layer.shadowOffset = CGSize(width: 0, height: 1)
            btn.layer.shadowRadius = 2
        }
        return btn
    }

    // MARK: - Actions Setup

    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        mainToggleButton.addTarget(self, action: #selector(handleMainToggle), for: .touchUpInside)
        subToggleButton.addTarget(self, action: #selector(handleSubToggle), for: .touchUpInside)
    }

    private func setupTextFields() {
        mainTextField.addTarget(self, action: #selector(mainTextChanged(_:)), for: .editingChanged)
        subTextField.addTarget(self, action: #selector(subTextChanged(_:)), for: .editingChanged)
    }

    @objc private func handleBack() { actionPublisher.send(.back) }
    @objc private func handleSave() { actionPublisher.send(.saveImage) }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        showTab(index: sender.selectedSegmentIndex)
    }

    @objc private func mainTextChanged(_ sender: UITextField) {
        actionPublisher.send(.mainTextChanged(sender.text ?? ""))
    }

    @objc private func subTextChanged(_ sender: UITextField) {
        actionPublisher.send(.subTextChanged(sender.text ?? ""))
    }

    @objc private func handleMainToggle() {
        if isMainVisible && !isSubVisible {
            shake(mainToggleButton)
            return
        }
        isMainVisible.toggle()
        mainTextField.isEnabled = isMainVisible
        mainTextField.alpha = isMainVisible ? 1 : 0.4
        updateLockedState()
        actionPublisher.send(.mainTextToggled(isMainVisible))
    }

    @objc private func handleSubToggle() {
        if isSubVisible && !isMainVisible {
            shake(subToggleButton)
            return
        }
        isSubVisible.toggle()
        subTextField.isEnabled = isSubVisible
        subTextField.alpha = isSubVisible ? 1 : 0.4
        updateLockedState()
        actionPublisher.send(.subTextToggled(isSubVisible))
    }

    /// 한쪽이 숨겨져 있을 때 반대쪽 버튼을 잠금 상태로 표시
    private func updateLockedState() {
        let mainLocked = !isSubVisible   // 서브가 없으면 메인 잠금
        let subLocked  = !isMainVisible  // 메인이 없으면 서브 잠금
        setToggleLocked(mainToggleButton, locked: mainLocked)
        setToggleLocked(subToggleButton,  locked: subLocked)
        // 잠긴 버튼이 생기는 시점에 미리 워밍업 → 탭 시 딜레이 없음
        if mainLocked || subLocked {
            feedbackGenerator.prepare()
        }
    }

    private func setToggleLocked(_ button: UIButton, locked: Bool) {
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if locked {
            button.setImage(UIImage(systemName: "lock", withConfiguration: cfg), for: .normal)
            button.tintColor = .textTertiary
            button.backgroundColor = .surfaceSecondary
            button.alpha = 0.45
        } else {
            let isVisible = button == mainToggleButton ? isMainVisible : isSubVisible
            button.setImage(UIImage(systemName: isVisible ? "eye" : "eye.slash", withConfiguration: cfg), for: .normal)
            button.tintColor = isVisible ? .textSecondary : .textHint
            button.backgroundColor = isVisible ? .surfaceSecondary : .background
            button.alpha = 1
        }
    }

    private func shake(_ view: UIView) {
        feedbackGenerator.notificationOccurred(.error)
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-6, 6, -4, 4, -2, 2, 0]
        anim.duration = 0.35
        view.layer.add(anim, forKey: "shake")
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < CardDecorateView.bgColors.count else { return }

        colorButtons[selectedColorIndex].layer.borderWidth = 1
        colorButtons[selectedColorIndex].layer.borderColor = UIColor.border.cgColor

        selectedColorIndex = index
        colorButtons[index].layer.borderWidth = 2.5
        colorButtons[index].layer.borderColor = UIColor.primary.cgColor

        let selected = CardDecorateView.bgColors[index]
        actionPublisher.send(.backgroundColorSelected(bg: selected.bg, stroke: selected.stroke))
    }

    @objc private func textColorButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < CardDecorateView.textColors.count else { return }

        textColorButtons[selectedTextColorIndex].layer.borderWidth = 1
        textColorButtons[selectedTextColorIndex].layer.borderColor = UIColor.border.cgColor

        selectedTextColorIndex = index
        textColorButtons[index].layer.borderWidth = 2.5
        textColorButtons[index].layer.borderColor = UIColor.primary.cgColor

        let selected = CardDecorateView.textColors[index]
        actionPublisher.send(.textColorSelected(selected.color))
    }

    // MARK: - Tab Switch

    private func showTab(index: Int) {
        textTabView.isHidden = index != 0
        colorTabView.isHidden = index != 1
    }

    // MARK: - Keyboard

    func dismissKeyboard() {
        endEditing(true)
    }
}

// MARK: - Factory

private func makeToggleButton() -> UIButton {
    let btn = UIButton(type: .system)
    btn.backgroundColor = .surfaceSecondary
    btn.layer.cornerRadius = 12
    btn.tintColor = .textSecondary
    let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
    btn.setImage(UIImage(systemName: "eye", withConfiguration: cfg), for: .normal)
    return btn
}
