//
//  TextEditorView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class TextEditorView: UIView {

    // MARK: - Callbacks
    var onBackTap: (() -> Void)?
    var onFontSizeChange: ((CGFloat) -> Void)?

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

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "내 손글씨"
        l.font = .bodyHeader
        l.textColor = .textPrimary
        return l
    }()

    // MARK: - Text View (커스텀 NSLayoutManager 주입)

    let textView: UITextView = {
        let storage = NSTextStorage()
        let layoutManager = GlyphLayoutManager()
        let container = NSTextContainer()
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)

        let tv = UITextView(frame: .zero, textContainer: container)
        tv.font = .custom(size: 32)
        tv.textColor = .label
        tv.backgroundColor = .systemBackground
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.showsHorizontalScrollIndicator = false
        tv.alwaysBounceHorizontal = false
        tv.alwaysBounceVertical = true // 짧은 텍스트라도 드래그로 키보드를 내릴 수 있도록 수직 바운스 허용
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "텍스트를 입력하세요"
        l.font = .cardTitle
        l.textColor = .textHint
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Font Size Control

    private let sizeControlView: UIView = {
        let v = UIView()
        v.backgroundColor = .surface
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.surfaceSecondary.cgColor
        return v
    }()

    private let sizeLabel: UILabel = {
        let l = UILabel()
        l.text = "글자 크기"
        l.font = .subLabel
        l.textColor = .textHint
        return l
    }()

    private lazy var sizeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["소", "중", "대"])
        sc.selectedSegmentIndex = 1
        sc.addTarget(self, action: #selector(sizeChanged), for: .valueChanged)
        return sc
    }()

    static let fontSizes: [CGFloat] = [20, 32, 48]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func setupLayout() {
        addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(titleLabel)

        addSubview(textView)
        textView.addSubview(placeholderLabel)   // 스크롤 시 위아래로 같이 바운스되도록 textView 내부에 추가

        addSubview(sizeControlView)
        sizeControlView.addSubview(sizeLabel)
        sizeControlView.addSubview(sizeSegment)

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

        sizeControlView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
        sizeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(14)
        }
        sizeSegment.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(160)
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(navBarView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(sizeControlView.snp.top)
        }

        // Y축은 텍스트 콘텐츠의 최상단(top)에 고정되어 위아래 스크롤/바운스 시 함께 움직이도록 하고,
        // X축(가로 너비)은 frameLayoutGuide에 고정시켜 스크롤뷰의 contentSize가 늘어나거나 잘리는 걸 방지합니다.
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.horizontalEdges.equalTo(textView.frameLayoutGuide).inset(22)
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let insets = textView.textContainerInset
        let w = textView.bounds.width - insets.left - insets.right
        guard w > 0 else { return }
        textView.textContainer.size = CGSize(width: w, height: .greatestFiniteMagnitude)
    }

    // MARK: - Public

    func setPlaceholderVisible(_ visible: Bool) {
        placeholderLabel.isHidden = !visible
    }

    @objc private func handleBack() { onBackTap?() }

    @objc private func sizeChanged() {
        let size = Self.fontSizes[sizeSegment.selectedSegmentIndex]
        onFontSizeChange?(size)
    }
}
