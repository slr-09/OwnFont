//
//  TextStickerView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class TextStickerView: UIView {

    var onTap: (() -> Void)?
    var onPanStateChanged: ((UIGestureRecognizer.State) -> Void)?

    private(set) var stickerText: String = ""
    private(set) var stickerFontSize: CGFloat = 36
    private(set) var stickerColor: UIColor = .white

    private lazy var textView: UITextView = makeTextView()
    private var currentScale: CGFloat = 1
    private var currentRotation: CGFloat = 0

    // MARK: - Init

    init(text: String, fontSize: CGFloat, color: UIColor) {
        super.init(frame: .zero)
        setupSubviews()
        setupGestures()
        configure(text: text, fontSize: fontSize, color: color)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupSubviews() {
        addSubview(textView)
        textView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinch.delegate = self

        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        rotation.delegate = self

        [tap, pan, pinch, rotation].forEach { addGestureRecognizer($0) }
    }

    // MARK: - Configure

    func configure(text: String, fontSize: CGFloat, color: UIColor) {
        stickerText = text
        stickerFontSize = fontSize
        stickerColor = color

        textView.attributedText = NSAttributedString(
            string: text,
            attributes: [.font: UIFont.custom(size: fontSize), .foregroundColor: color]
        )
        textView.textAlignment = .center
        GlyphKerning.apply(to: textView.textStorage)

        let maxWidth = min(UIScreen.main.bounds.width - 40, 300.0)
        let inset = textView.textContainerInset
        let measured = measureFinalSize(maxWidth: maxWidth)

        frame.size = CGSize(
            width: max(measured.width, fontSize + inset.left + inset.right),
            height: max(measured.height, fontSize + inset.top + inset.bottom)
        )
    }

    // MARK: - Size Measurement

    private func measureFinalSize(maxWidth: CGFloat) -> CGSize {
        let inset = textView.textContainerInset

        textView.textContainer.size = CGSize(width: 10000, height: 10000)
        let naturalSize = textView.sizeThatFits(CGSize(width: 10000, height: 10000))

        if naturalSize.width <= maxWidth {
            textView.textContainer.size = CGSize(
                width: naturalSize.width - inset.left - inset.right,
                height: .greatestFiniteMagnitude
            )
            return CGSize(width: ceil(naturalSize.width), height: ceil(naturalSize.height))
        } else {
            textView.textContainer.size = CGSize(
                width: maxWidth - inset.left - inset.right,
                height: .greatestFiniteMagnitude
            )
            let wrappedSize = textView.sizeThatFits(CGSize(width: maxWidth, height: 10000))
            return CGSize(width: maxWidth, height: ceil(wrappedSize.height))
        }
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap() {
        superview?.bringSubviewToFront(self)
        onTap?()
    }

    @objc private func handlePan(_ r: UIPanGestureRecognizer) {
        guard let sv = superview else { return }
        let t = r.translation(in: sv)
        center = CGPoint(x: center.x + t.x, y: center.y + t.y)
        r.setTranslation(.zero, in: sv)

        switch r.state {
        case .began:
            sv.bringSubviewToFront(self)
            onPanStateChanged?(.began)
        case .changed, .ended, .cancelled, .failed:
            onPanStateChanged?(r.state)
        default:
            break
        }
    }

    @objc private func handlePinch(_ r: UIPinchGestureRecognizer) {
        currentScale = max(0.3, min(currentScale * r.scale, 5))
        r.scale = 1
        applyTransform()
    }

    @objc private func handleRotation(_ r: UIRotationGestureRecognizer) {
        currentRotation += r.rotation
        r.rotation = 0
        applyTransform()
    }

    private func applyTransform() {
        transform = CGAffineTransform(rotationAngle: currentRotation).scaledBy(x: currentScale, y: currentScale)
    }

    // MARK: - Factory

    private func makeTextView() -> UITextView {
        let storage = NSTextStorage()
        let layoutManager = GlyphLayoutManager()
        let container = NSTextContainer()
        container.widthTracksTextView = false
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)

        let tv = UITextView(frame: .zero, textContainer: container)
        tv.backgroundColor = .clear
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        return tv
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextStickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}
