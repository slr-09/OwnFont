//
//  CharacterCanvasView.swift
//  OwnFont
//

import UIKit
import PencilKit
import SnapKit

final class CharacterCanvasView: UIView {

    // MARK: - Subviews

    private let guideCharLabel: UILabel = {
        let label = UILabel()
        label.font = .guideLabel
        label.textColor = .primarySubtle
        label.textAlignment = .center
        label.alpha = 0.5
        return label
    }()

    let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        return canvas
    }()

    private let toolPicker = PKToolPicker()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.surfaceSecondary.cgColor
        clipsToBounds = true

        addSubview(guideCharLabel)
        guideCharLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(canvasView)
        canvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func setGuideChar(_ char: String) {
        guideCharLabel.text = char
    }

    /// ViewController의 viewDidAppear 이후 호출
    func activateToolPicker() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    func clearDrawing() {
        canvasView.drawing = PKDrawing()
    }

    func usePen() {
        canvasView.tool = PKInkingTool(.monoline, color: .black, width: 5)
    }

    func useEraser() {
        canvasView.tool = PKEraserTool(.bitmap)
    }

    func undo() {
        canvasView.undoManager?.undo()
    }

    var drawing: PKDrawing {
        get { canvasView.drawing }
        set { canvasView.drawing = newValue }
    }

    // MARK: - Draw (격자선)

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let w = rect.width
        let h = rect.height

        ctx.setStrokeColor(UIColor.surfaceSecondary.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 0, y: h / 3));      ctx.addLine(to: CGPoint(x: w, y: h / 3))
        ctx.move(to: CGPoint(x: 0, y: h * 2 / 3));  ctx.addLine(to: CGPoint(x: w, y: h * 2 / 3))
        ctx.move(to: CGPoint(x: w / 3, y: 0));       ctx.addLine(to: CGPoint(x: w / 3, y: h))
        ctx.move(to: CGPoint(x: w * 2 / 3, y: 0));   ctx.addLine(to: CGPoint(x: w * 2 / 3, y: h))
        ctx.strokePath()
    }
}
