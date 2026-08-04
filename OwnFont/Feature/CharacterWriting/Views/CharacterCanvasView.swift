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
    private var previewDrawing: PKDrawing?
    private var lastPreviewSize: CGSize = .zero
    private var isCanvasAttached = false

    /// 캔버스가 분리된 상태에서 이 뷰 영역에 터치가 처음 닿았을 때 호출된다.
    /// (예: 포커스 없는 셀을 탭 없이 바로 펜슬로 긋기 시작하는 경우)
    var onTouchWhileDetached: (() -> Void)?

    private let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleToFill
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = UIDevice.current.userInterfaceIdiom == .pad ? .pencilOnly : .anyInput
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

        addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        previewImageView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hit Testing

    /// 캔버스가 붙어있지 않은 상태(미포커스 셀)에서 탭 없이 곧바로 펜슬 획이 시작되면
    /// UITapGestureRecognizer는 이동이 있는 터치를 탭으로 인식하지 못해 실패하고,
    /// 그 결과 onFocusRequest가 호출되지 않아 캔버스가 영영 붙지 않는다.
    /// 그 사이 터치는 상위 UICollectionView의 스크롤 팬 제스처가 가져가버려
    /// "그려지지 않고 스크롤만 되는" 증상으로 이어진다.
    /// 터치가 실제로 라우팅되기 전(hitTest)에 캔버스를 동기적으로 붙여
    /// 같은 터치가 바로 캔버스로 전달되도록 한다.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isCanvasAttached, bounds.contains(point) {
            onTouchWhileDetached?()
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.height > 0, bounds.height != lastGuideHeight {
            lastGuideHeight = bounds.height
            updateGuideLayout()
        }
        updatePreviewImageIfNeeded()
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

    /// 편집 중인 셀만 canvasView를 뷰 계층에 붙인다.
    /// PKCanvasView는 레이아웃이 한 번이라도 돌면 내부적으로 Metal 기반 tile renderer를
    /// 생성하므로, 편집하지 않는 셀까지 붙여두면 그리드 스크롤만으로 GPU 메모리가 급증해
    /// bad_alloc 크래시로 이어진다. 포커스를 잃으면 즉시 떼어내 layoutSubviews 자체가
    /// 돌지 않게 한다.
    private func attachCanvasIfNeeded() {
        guard !isCanvasAttached else { return }
        insertSubview(canvasView, belowSubview: previewImageView)
        canvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        isCanvasAttached = true
    }

    private func detachCanvasIfNeeded() {
        guard isCanvasAttached else { return }
        canvasView.removeFromSuperview()
        isCanvasAttached = false
    }

    /// 미리보기 모드(그리드의 미포커스 셀)라면 실제 캔버스를 붙이지 않고 미리보기 이미지만 비운다.
    /// 그 외(편집 모드이거나, 아직 편집/미리보기 모드가 정해지지 않은 초기 상태 — 예: 저장된
    /// 드로잉이 없는 새 글자를 처음 보여줄 때)에는 캔버스를 편집 가능한 빈 상태로 만든다.
    /// 과거에는 이미 붙어있는 캔버스만 비웠는데, CharacterWritingViewController처럼 캔버스가
    /// 한 번도 붙은 적 없는 화면에서 clearDrawing()이 아무 효과도 내지 못해(붙지 않은 채로 남아)
    /// 아예 그려지지 않는 문제가 있었다.
    func clearDrawing() {
        guard previewImageView.isHidden else {
            previewDrawing = nil
            previewImageView.image = nil
            return
        }
        setEditableDrawing(nil)
    }

    func usePen() {
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 5
        canvasView.tool = PKInkingTool(.monoline, color: .black, width: width)
    }

    func useEraser() {
        canvasView.tool = PKEraserTool(.bitmap)
    }

    func undo() {
        guard !canvasView.isHidden, window != nil, canvasView.undoManager?.canUndo == true else { return }
        canvasView.undoManager?.undo()
    }

    var drawing: PKDrawing {
        get { canvasView.isHidden ? (previewDrawing ?? PKDrawing()) : canvasView.drawing }
        set { setEditableDrawing(newValue) }
    }

    func setEditableDrawing(_ drawing: PKDrawing?) {
        previewDrawing = nil
        previewImageView.image = nil
        previewImageView.isHidden = true
        attachCanvasIfNeeded()
        canvasView.isHidden = false
        canvasView.isUserInteractionEnabled = true
        canvasView.drawing = drawing ?? PKDrawing()
        canvasView.undoManager?.removeAllActions()
    }

    func setPreviewDrawing(_ drawing: PKDrawing?) {
        previewDrawing = drawing
        previewImageView.isHidden = false
        canvasView.isUserInteractionEnabled = false
        canvasView.isHidden = true
        detachCanvasIfNeeded()
        updatePreviewImageIfNeeded(force: true)
    }

    private func updatePreviewImageIfNeeded(force: Bool = false) {
        guard !previewImageView.isHidden else { return }
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return }
        guard force || size != lastPreviewSize else { return }
        lastPreviewSize = size

        guard let previewDrawing, !previewDrawing.strokes.isEmpty else {
            previewImageView.image = nil
            return
        }

        let renderBounds = CGRect(origin: .zero, size: size)
        previewImageView.image = previewDrawing.image(from: renderBounds, scale: UIScreen.main.scale)
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
