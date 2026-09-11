//
//  CharacterWritingGridCell.swift
//  OwnFont
//

import UIKit
import PencilKit
import SnapKit

final class CharacterWritingGridCell: UICollectionViewCell, PKCanvasViewDelegate {

    static let reuseID = "CharacterWritingGridCell"

    // MARK: - Subviews
    private let charLabel: UILabel = {
        let l = UILabel()
        l.font = .caption
        l.textColor = .textHint
        return l
    }()

    private let completionBadge: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .primary
        iv.isHidden = true
        return iv
    }()

    let canvasContainer = CharacterCanvasView()

    // MARK: - Callbacks
    var onFocusRequest: (() -> Void)?
    var onDrawingChanged: ((PKDrawing) -> Void)?
    private var cachedDrawing: PKDrawing?
    private var isCellFocused = false
    private var isApplyingProgrammaticDrawing = false

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupGesture()
        canvasContainer.canvasView.delegate = self
        canvasContainer.onTouchWhileDetached = { [weak self] in
            self?.onFocusRequest?()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.backgroundColor = .surface
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1.5
        contentView.layer.borderColor = UIColor.surfaceSecondary.cgColor
        contentView.layer.masksToBounds = true

        contentView.addSubview(charLabel)
        contentView.addSubview(completionBadge)
        contentView.addSubview(canvasContainer)

        charLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(8)
        }
        completionBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(16)
        }
        canvasContainer.snp.makeConstraints { make in
            make.top.equalTo(charLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onFocusRequest?()
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        onFocusRequest = nil
        onDrawingChanged = nil
        cachedDrawing = nil
        isCellFocused = false
        isApplyingProgrammaticDrawing = true
        canvasContainer.clearDrawing()
        canvasContainer.setPreviewDrawing(nil)
        isApplyingProgrammaticDrawing = false
        canvasContainer.setGuideChar("")
        charLabel.text = nil
        completionBadge.isHidden = true
        setFocused(false)
    }

    // MARK: - Configure
    func configure(character: String, drawing: PKDrawing?, isCompleted: Bool, isFocused: Bool) {
        // 콜백을 잠시 비워 drawing 대입 중 delegate 발화로 오작동하는 것을 방지
        onFocusRequest = nil
        onDrawingChanged = nil
        charLabel.text = character
        canvasContainer.setGuideChar(character)
        cachedDrawing = drawing
        completionBadge.isHidden = !isCompleted
        isCellFocused = isFocused
        applyCanvasMode(focused: isFocused)
        updateFocusBorder(isFocused)
    }

    func setFocused(_ focused: Bool) {
        guard focused != isCellFocused else {
            updateFocusBorder(focused)
            return
        }
        if !focused, isCellFocused {
            cachedDrawing = canvasContainer.drawing
        }
        isCellFocused = focused
        applyCanvasMode(focused: focused)
        updateFocusBorder(focused)
    }

    private func applyCanvasMode(focused: Bool) {
        isApplyingProgrammaticDrawing = true
        if focused {
            canvasContainer.setEditableDrawing(cachedDrawing)
        } else {
            canvasContainer.setPreviewDrawing(cachedDrawing)
        }
        isApplyingProgrammaticDrawing = false
    }

    private func updateFocusBorder(_ focused: Bool) {
        contentView.layer.borderColor = (focused ? UIColor.primary : UIColor.surfaceSecondary).cgColor
        contentView.layer.borderWidth = focused ? 2.5 : 1.5
    }

    func setCompleted(_ completed: Bool) {
        completionBadge.isHidden = !completed
    }

    // MARK: - PKCanvasViewDelegate
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        onFocusRequest?()
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard !isApplyingProgrammaticDrawing else { return }
        cachedDrawing = canvasView.drawing
        onDrawingChanged?(canvasView.drawing)
    }
}
