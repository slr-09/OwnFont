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

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupGesture()
        canvasContainer.canvasView.delegate = self
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
        canvasContainer.clearDrawing()
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
        if let drawing {
            canvasContainer.drawing = drawing
        } else {
            canvasContainer.clearDrawing()
        }
        completionBadge.isHidden = !isCompleted
        setFocused(isFocused)
    }

    func setFocused(_ focused: Bool) {
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
        onDrawingChanged?(canvasView.drawing)
    }
}
