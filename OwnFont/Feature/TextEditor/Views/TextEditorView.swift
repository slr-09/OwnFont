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
        l.text = "텍스트 에디터"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .textPrimary
        return l
    }()

    private let badgeView: UIView = {
        let v = UIView()
        v.backgroundColor = .primaryLight
        v.layer.cornerRadius = 12
        return v
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.text = "손글씨 폰트"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .primary
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
        tv.font = .systemFont(ofSize: 32, weight: .regular)
        tv.textColor = .label
        tv.backgroundColor = .systemBackground
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.showsHorizontalScrollIndicator = false
        tv.alwaysBounceHorizontal = false
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "타이핑하면 손글씨 폰트로 표시돼요"
        l.font = .systemFont(ofSize: 32, weight: .regular)
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
        l.font = .systemFont(ofSize: 13, weight: .medium)
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
        navBarView.addSubview(badgeView)
        badgeView.addSubview(badgeLabel)

        addSubview(textView)
        addSubview(placeholderLabel)   // textView 바깥: UIScrollView 내부 → contentSize 기준 잘림 방지

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
        badgeView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
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

        // textView.frameLayoutGuide: 스크롤과 무관한 실제 화면 프레임 기준
        // textContainerInset(top:20, left:16)과 맞춰 텍스트 시작점과 일치시킴
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.frameLayoutGuide).offset(20)
            make.leading.equalTo(textView.frameLayoutGuide).offset(16)
            make.trailing.equalTo(textView.frameLayoutGuide).offset(-16)
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
