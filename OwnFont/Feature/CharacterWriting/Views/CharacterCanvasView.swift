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
        label.textColor = .primarySubtle
        label.textAlignment = .center
        label.alpha = 0.5
        return label
    }()

    private var lastGuideHeight: CGFloat = 0
    private var guideBaselineConstraint: Constraint?

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

        addSubview(guideCharLabel)
        guideCharLabel.snp.makeConstraints { make in
            guideBaselineConstraint = make.firstBaseline.equalTo(snp.top).offset(0).constraint
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }

        addSubview(canvasView)
        canvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.height > 0, bounds.height != lastGuideHeight else { return }
        lastGuideHeight = bounds.height
        updateGuideLayout()
    }

    // 캔버스 = em 전체(0~1000) 표현. 베이스라인은 상단 85% 지점.
    // 가이드 폰트의 ascender가 베이스라인 위 영역(= 0.85 × canvasHeight)을 채우도록 크기 계산
    private func updateGuideLayout() {
        let baselineOffset = bounds.height * GlyphNormalizer.baselineRatio
        guideBaselineConstraint?.update(offset: baselineOffset)

        let fontName = "NoonnuBasicGothicRegular"
        let refFont = UIFont(name: fontName, size: 100) ?? UIFont.systemFont(ofSize: 100)
        let ascenderRatio = refFont.ascender / refFont.pointSize
        let targetSize = baselineOffset / ascenderRatio
        guideCharLabel.font = UIFont(name: fontName, size: targetSize)
            ?? UIFont.systemFont(ofSize: targetSize)
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
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 5
        canvasView.tool = PKInkingTool(.monoline, color: .black, width: width)
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

        // 격자선
        ctx.setStrokeColor(UIColor.surfaceSecondary.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 0, y: h / 3));      ctx.addLine(to: CGPoint(x: w, y: h / 3))
        ctx.move(to: CGPoint(x: 0, y: h * 2 / 3));  ctx.addLine(to: CGPoint(x: w, y: h * 2 / 3))
        ctx.move(to: CGPoint(x: w / 3, y: 0));       ctx.addLine(to: CGPoint(x: w / 3, y: h))
        ctx.move(to: CGPoint(x: w * 2 / 3, y: 0));   ctx.addLine(to: CGPoint(x: w * 2 / 3, y: h))
        ctx.strokePath()

        // 베이스라인 (em y=150 → 캔버스 상단 85% 지점)
        let baselineY = h * GlyphNormalizer.baselineRatio
        ctx.setStrokeColor(UIColor.primarySubtle.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: 0, y: baselineY))
        ctx.addLine(to: CGPoint(x: w, y: baselineY))
        ctx.strokePath()
    }
}
