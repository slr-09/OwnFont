//
//  MemoCardView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class MemoCardView: UIView {

    // MARK: - Subviews

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.isHidden = true
        return iv
    }()

    private let photoOverlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.layer.cornerRadius = 20
        v.isHidden = true
        return v
    }()

    private let headerRow: UIView = {
        let v = UIView()
        return v
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .badge
        l.textColor = .textHint
        return l
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = .amberBorder
        return v
    }()

    // UILabel 대신 GlyphLayoutManager가 주입된 UITextView 사용
    private let mainTextView: UITextView = makeGlyphTextView(fontSize: 20, textColor: .textPrimary)
    private let subTextView: UITextView = makeGlyphTextView(fontSize: 16, textColor: .iconInactive)

    // MARK: - Placeholder

    private let mainPlaceholder = "오늘의 한 줄"
    private let subPlaceholder = "추가 메모"

    // MARK: - Visibility State

    private var isMainVisible = true
    private var isSubVisible = true

    // MARK: - Text Color State

    private var mainActiveColor: UIColor = .textPrimary
    private var subActiveColor: UIColor = .textPrimary

    // MARK: - Placeholder State

    private var isMainPlaceholder = true
    private var isSubPlaceholder = true

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupAppearance() {
        backgroundColor = UIColor(hex: "FFFBEB")
        layer.cornerRadius = 20
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.amberBorder.cgColor
    }

    private func setupLayout() {
        insertSubview(backgroundImageView, at: 0)
        insertSubview(photoOverlayView, at: 1)
        backgroundImageView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        backgroundImageView.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        backgroundImageView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        backgroundImageView.setContentCompressionResistancePriority(.defaultLow - 1, for: .vertical)
        backgroundImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        photoOverlayView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        addSubview(headerRow)
        headerRow.addSubview(dateLabel)
        addSubview(divider)
        addSubview(mainTextView)
        addSubview(subTextView)

        headerRow.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
        dateLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        updateVisibilityLayout()
    }

    // MARK: - Public Interface

    func configure(date: String? = nil, mainText: String? = nil, subText: String? = nil) {
        if let date { dateLabel.text = date }
        if let mainText { updateTextView(mainTextView, text: mainText, placeholder: mainPlaceholder, activeColor: mainActiveColor) }
        if let subText  { updateTextView(subTextView,  text: subText,  placeholder: subPlaceholder,  activeColor: subActiveColor) }
    }

    // MARK: - Private

    private func updateTextView(_ tv: UITextView, text: String, placeholder: String, activeColor: UIColor) {
        let isEmpty = text.isEmpty
        if tv === mainTextView { isMainPlaceholder = isEmpty }
        else { isSubPlaceholder = isEmpty }

        let (displayText, color) = isEmpty ? (placeholder, UIColor.textHint) : (text, activeColor)
        tv.text = displayText
        let range = NSRange(location: 0, length: tv.textStorage.length)
        tv.textStorage.addAttribute(.foregroundColor, value: color, range: range)
        GlyphKerning.apply(to: tv.textStorage)
        tv.invalidateIntrinsicContentSize()
    }

    func setBackgroundImage(_ image: UIImage?) {
        if let image {
            backgroundImageView.image = image
            backgroundImageView.isHidden = false
            photoOverlayView.isHidden = false
        } else {
            backgroundImageView.isHidden = true
            photoOverlayView.isHidden = true
        }
    }

    func setBackground(_ color: UIColor, stroke: UIColor) {
        backgroundColor = color
        layer.borderColor = stroke.cgColor
        divider.backgroundColor = stroke
    }

    func setTextColor(_ color: UIColor) {
        mainActiveColor = color
        subActiveColor = color
        if !isMainPlaceholder {
            let range = NSRange(location: 0, length: mainTextView.textStorage.length)
            mainTextView.textStorage.addAttribute(.foregroundColor, value: color, range: range)
        }
        if !isSubPlaceholder {
            let range = NSRange(location: 0, length: subTextView.textStorage.length)
            subTextView.textStorage.addAttribute(.foregroundColor, value: color, range: range)
        }
    }

    func setMainVisible(_ visible: Bool) {
        isMainVisible = visible
        mainTextView.isHidden = !visible
        updateVisibilityLayout()
    }

    func setSubVisible(_ visible: Bool) {
        isSubVisible = visible
        subTextView.isHidden = !visible
        updateVisibilityLayout()
    }

    // MARK: - Layout

    private func updateVisibilityLayout() {
        mainTextView.snp.remakeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(6)
            make.horizontalEdges.equalToSuperview().inset(14)
            if isMainVisible && !isSubVisible {
                make.bottom.equalToSuperview().inset(14)
            }
        }
        subTextView.snp.remakeConstraints { make in
            make.top.equalTo(isMainVisible ? mainTextView.snp.bottom : divider.snp.bottom)
                .offset(isMainVisible ? 2 : 10)
            make.horizontalEdges.equalToSuperview().inset(14)
            if isSubVisible {
                make.bottom.equalToSuperview().inset(14)
            }
        }
        divider.snp.remakeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
    }
}

// MARK: - Factory

/// GlyphLayoutManager가 주입된 표시 전용 UITextView를 생성합니다.
private func makeGlyphTextView(fontSize: CGFloat, textColor: UIColor) -> UITextView {
    let storage = NSTextStorage()
    let layout = GlyphLayoutManager()
    let container = NSTextContainer()
    container.widthTracksTextView = true
    layout.addTextContainer(container)
    storage.addLayoutManager(layout)

    let tv = UITextView(frame: .zero, textContainer: container)
    tv.font = .custom(size: fontSize)
    tv.textColor = textColor
    tv.backgroundColor = .clear
    tv.isEditable = false
    tv.isScrollEnabled = false
    tv.isSelectable = false
    tv.textContainerInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    tv.textContainer.lineFragmentPadding = 0
    tv.autocorrectionType = .no
    return tv
}
