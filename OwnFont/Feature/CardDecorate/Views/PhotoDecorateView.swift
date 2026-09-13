//
//  PhotoDecorateView.swift
//  OwnFont
//

import Combine
import UIKit
import SnapKit

final class PhotoDecorateView: UIView {

    // MARK: - Types

    enum Action {
        case back
        case save
        case share
        case textStickerAdded
    }

    // MARK: - Publisher

    let actionPublisher = PassthroughSubject<Action, Never>()
    private(set) var hasUnsavedChanges: Bool = false

    // MARK: - Private State

    private var lastPhotoImageBounds: CGRect = .zero
    private var editingSticker: TextStickerView?
    private weak var overlayView: UIView?
    private weak var overlayCloseButton: UIButton?
    private weak var overlayDoneButton: UIButton?
    private weak var overlayControlsBar: UIView?
    private weak var overlayTextView: UITextView?
    private weak var canvasPinchSticker: TextStickerView?
    private weak var canvasRotationSticker: TextStickerView?
    private var currentTextColor: UIColor = .white
    private var currentFontSize: CGFloat = 36
    private var colorChips: [UIButton] = []
    private var isTrashHighlighted: Bool = false
    private var cancellables = Set<AnyCancellable>()
    /// 저장/공유용 합성이 진행 중인지 여부. 완료 전 재탭으로 무거운 합성
    /// 작업이 중복 실행되어 메모리 피크가 배가되는 것을 막는다.
    private var isExportingImage = false

    private static let stickerColors: [UIColor] = [
        .white, .black, .systemPink, .systemOrange, .systemGreen, .systemYellow, .systemBlue, .systemPurple
    ]
    private static let fontSizes: [CGFloat] = [24, 36, 52]
    /// 저장 시 렌더링 결과물의 최대 변 길이(px). 사진첩에서 확대해도 체감 차이가
    /// 크지 않은 선에서, 저장 시 순간 메모리 사용량을 낮추기 위한 상한선.
    private static let maxExportDimension: CGFloat = 3000

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
        l.text = L.photoDecorateTitle
        l.font = .cardHeader
        l.textColor = .textPrimary
        return l
    }()

    private let shareButton = InstagramShareButton()

    private let textButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .surfaceSecondary
        btn.layer.cornerRadius = 18
        btn.tintColor = .textPrimary
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "textformat", withConfiguration: cfg), for: .normal)
        return btn
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .primary
        btn.layer.cornerRadius = 16
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            L.buttonSave,
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

    // MARK: - Photo & Sticker Canvas

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let stickerCanvas: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.clipsToBounds = true
        return v
    }()

    // MARK: - Trash Zone

    private let trashView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        v.layer.cornerRadius = 28
        v.isHidden = true
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

    private let trashIcon: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iv.image = UIImage(systemName: "trash.fill", withConfiguration: cfg)
        iv.tintColor = .white
        iv.contentMode = .center
        return iv
    }()

    // MARK: - Init

    init(photo: UIImage) {
        super.init(frame: .zero)
        photoImageView.image = photo
        backgroundColor = .background
        setupLayout()
        setupActions()
        setupKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard photoImageView.bounds != lastPhotoImageBounds else { return }
        lastPhotoImageBounds = photoImageView.bounds
        updateStickerCanvasFrame()
    }

    private func updateStickerCanvasFrame() {
        guard let image = photoImageView.image else { return }
        let viewSize = photoImageView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        let imageSize = image.size
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let x = (viewSize.width - scaledSize.width) / 2
        let y = (viewSize.height - scaledSize.height) / 2

        let oldSize = stickerCanvas.bounds.size
        stickerCanvas.frame = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
        repositionStickers(from: oldSize, to: scaledSize)
    }

    /// 캔버스 크기가 바뀌면(예: 회전) 스티커가 원래 위치 비율을 유지하도록 center 를 보정한다.
    private func repositionStickers(from oldSize: CGSize, to newSize: CGSize) {
        guard oldSize.width > 0, oldSize.height > 0,
              newSize.width > 0, newSize.height > 0,
              oldSize != newSize else { return }
        let scaleX = newSize.width / oldSize.width
        let scaleY = newSize.height / oldSize.height
        for case let sticker as TextStickerView in stickerCanvas.subviews {
            sticker.center = CGPoint(x: sticker.center.x * scaleX,
                                     y: sticker.center.y * scaleY)
        }
    }

    private func setupLayout() {
        addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(textButton)
        navBarView.addSubview(saveButton)
        addSubview(photoImageView)
        photoImageView.addSubview(stickerCanvas)
        addSubview(trashView)
        addSubview(shareButton)
        trashView.addSubview(trashIcon)

        trashView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).inset(24)
            make.size.equalTo(56)
        }
        trashIcon.snp.makeConstraints { $0.center.equalToSuperview() }

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
        shareButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(navBarView.snp.bottom).offset(4)
            make.height.equalTo(28)
        }
        textButton.snp.makeConstraints { make in
            make.trailing.equalTo(saveButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(navBarView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(20)
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(handleAddText), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(handleShare), for: .touchUpInside)

        let canvasPinch = UIPinchGestureRecognizer(target: self, action: #selector(handleCanvasPinch))
        canvasPinch.delegate = self
        stickerCanvas.addGestureRecognizer(canvasPinch)

        let canvasRotation = UIRotationGestureRecognizer(target: self, action: #selector(handleCanvasRotation))
        canvasRotation.delegate = self
        stickerCanvas.addGestureRecognizer(canvasRotation)
    }

    @objc private func handleBack()    { actionPublisher.send(.back) }
    @objc private func handleSave()    { actionPublisher.send(.save) }
    @objc private func handleShare()   { actionPublisher.send(.share) }
    @objc private func handleAddText() {
        showTextEditOverlay(editing: nil)
    }

    @objc private func handleCanvasPinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            canvasPinchSticker = canvasGestureCandidate(for: recognizer)
            if let sticker = canvasPinchSticker {
                sticker.superview?.bringSubviewToFront(sticker)
            }
            fallthrough
        case .changed:
            canvasPinchSticker?.scale(by: recognizer.scale)
            recognizer.scale = 1
        case .ended, .cancelled, .failed:
            canvasPinchSticker = nil
            recognizer.scale = 1
        default:
            break
        }
    }

    @objc private func handleCanvasRotation(_ recognizer: UIRotationGestureRecognizer) {
        switch recognizer.state {
        case .began:
            canvasRotationSticker = canvasGestureCandidate(for: recognizer)
            if let sticker = canvasRotationSticker {
                sticker.superview?.bringSubviewToFront(sticker)
            }
            fallthrough
        case .changed:
            canvasRotationSticker?.rotate(by: recognizer.rotation)
            recognizer.rotation = 0
        case .ended, .cancelled, .failed:
            canvasRotationSticker = nil
            recognizer.rotation = 0
        default:
            break
        }
    }

    private func canvasGestureCandidate(for recognizer: UIGestureRecognizer) -> TextStickerView? {
        guard recognizer.numberOfTouches >= 2 else { return nil }

        var touchedStickers: [TextStickerView] = []
        for index in 0..<recognizer.numberOfTouches {
            let point = recognizer.location(ofTouch: index, in: stickerCanvas)
            guard let sticker = topmostSticker(containing: point),
                  !touchedStickers.contains(where: { $0 === sticker }) else { continue }
            touchedStickers.append(sticker)
        }

        guard touchedStickers.count == 1, let sticker = touchedStickers.first else { return nil }

        let allTouchesInsideSticker = (0..<recognizer.numberOfTouches).allSatisfy { index in
            let point = recognizer.location(ofTouch: index, in: stickerCanvas)
            let stickerPoint = stickerCanvas.convert(point, to: sticker)
            return sticker.bounds.contains(stickerPoint)
        }
        return allTouchesInsideSticker ? nil : sticker
    }

    private func topmostSticker(containing point: CGPoint) -> TextStickerView? {
        for case let sticker as TextStickerView in stickerCanvas.subviews.reversed() {
            let stickerPoint = stickerCanvas.convert(point, to: sticker)
            if sticker.bounds.contains(stickerPoint) { return sticker }
        }
        return nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.view === stickerCanvas else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        if let pinch = gestureRecognizer as? UIPinchGestureRecognizer {
            return canvasGestureCandidate(for: pinch) != nil
        }
        if gestureRecognizer is UIRotationGestureRecognizer {
            return canvasGestureCandidate(for: gestureRecognizer) != nil
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    // MARK: - Public

    /// 원본 사진 + 스티커를 합성해 JPEG로 내보낸다.
    ///
    /// 사진 레이어는 `drawHierarchy`로 캡처하지 않는다 — `UIImageView`가 화면
    /// 표시를 위해 만들어둔 저해상도 캐시(콘텐츠 텍스처)를 그대로 재사용해,
    /// 아무리 렌더링 scale을 올려도 확대된 저화질 이미지가 나오기 때문이다.
    /// 대신 원본 `UIImage`를 직접 그려 항상 원본 픽셀 데이터를 사용한다.
    ///
    /// 원본 해상도(최대 수천 px) 합성·인코딩은 무거운 작업이라 메인 스레드에서
    /// 동기 실행하면 UI가 멈추고 메모리 압박으로 크래시할 수 있다. `drawHierarchy`
    /// 자체(스티커 스냅샷)만 메인 스레드에서 짧게 캡처하고, 나머지 합성·인코딩은
    /// 백그라운드 큐로 넘긴다. PNG 대신 JPEG로 인코딩해 메모리 사용량과 최종
    /// 파일 크기도 함께 줄인다.
    ///
    /// 완료 전 재호출은 진행 중인 작업을 그대로 두고 무시한다 — 저장 버튼을
    /// 빠르게 여러 번 누르면 무거운 합성이 중복 실행되어 메모리 피크가
    /// 배가되는 것을 막기 위함이다.
    func renderCompositeImage(completion: @escaping (Data) -> Void) {
        guard !isExportingImage else { return }

        guard let baseImage = photoImageView.image,
              stickerCanvas.bounds.width > 0, stickerCanvas.bounds.height > 0 else {
            completion(legacyRenderCompositeImage())
            return
        }

        let nativePixelSize = CGSize(
            width: baseImage.size.width * baseImage.scale,
            height: baseImage.size.height * baseImage.scale
        )
        let longSide = max(nativePixelSize.width, nativePixelSize.height)
        let clampRatio = longSide > Self.maxExportDimension ? Self.maxExportDimension / longSide : 1
        let outputSize = CGSize(
            width: nativePixelSize.width * clampRatio,
            height: nativePixelSize.height * clampRatio
        )
        // 손상된 이미지 등으로 크기가 0이 되는 극단적인 경우, 0 크기 렌더러를
        // 만들면 크래시하므로 방어적으로 대체 경로를 탄다.
        guard outputSize.width > 0, outputSize.height > 0 else {
            completion(legacyRenderCompositeImage())
            return
        }

        let canvasSize = stickerCanvas.bounds.size
        let stickerScale = min(outputSize.width / canvasSize.width, outputSize.height / canvasSize.height)

        // 스티커가 없으면 스냅샷 자체를 생략해 불필요한 대형 비트맵 할당을 피한다.
        var stickerImage: UIImage?
        if !stickerCanvas.subviews.isEmpty {
            let stickerFormat = UIGraphicsImageRendererFormat()
            stickerFormat.opaque = false
            stickerFormat.scale = stickerScale
            let stickerRenderer = UIGraphicsImageRenderer(bounds: stickerCanvas.bounds, format: stickerFormat)
            // drawHierarchy는 UIKit 뷰 상태에 접근하므로 반드시 메인 스레드에서 호출한다.
            stickerImage = stickerRenderer.image { _ in
                stickerCanvas.drawHierarchy(in: stickerCanvas.bounds, afterScreenUpdates: true)
            }
        }

        isExportingImage = true
        setExportControlsEnabled(false)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let data: Data = autoreleasepool {
                let format = UIGraphicsImageRendererFormat()
                format.opaque = true
                // outputSize는 이미 "최종 픽셀 크기"로 계산해뒀으므로, scale을 명시적으로
                // 1로 고정해야 한다. 그렇지 않으면 기기 화면 배율(예: 3x)이 한 번 더
                // 곱해져 의도한 것보다 훨씬 큰(그리고 훨씬 무거운) 이미지가 만들어진다.
                format.scale = 1
                let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
                // renderer.image{}.jpegData(...) 는 완성된 UIImage/CGImage 사본을 한 번 더
                // 만든 뒤에야 인코딩하므로, 원본 해상도 버퍼가 순간적으로 하나 더 늘어난다.
                // jpegData(withCompressionQuality:actions:)를 쓰면 컨텍스트에서 바로
                // 인코딩해 그 중복 사본을 없앨 수 있다.
                return renderer.jpegData(withCompressionQuality: 0.92) { ctx in
                    // 원본보다 축소해서 그리는 경우가 많으므로, 리샘플링 품질을 최대로 지정한다.
                    ctx.cgContext.interpolationQuality = .high
                    baseImage.draw(in: CGRect(origin: .zero, size: outputSize))
                    stickerImage?.draw(in: CGRect(origin: .zero, size: outputSize))
                }
            }
            DispatchQueue.main.async {
                guard let self else {
                    completion(data)
                    return
                }
                self.isExportingImage = false
                self.setExportControlsEnabled(true)
                completion(data)
            }
        }
    }

    /// 저장/공유 진행 중 버튼을 비활성화하고, 저장 버튼에는 로딩 스피너를 보여준다.
    private func setExportControlsEnabled(_ enabled: Bool) {
        saveButton.isEnabled = enabled
        shareButton.isEnabled = enabled
        shareButton.alpha = enabled ? 1 : 0.5

        var config = saveButton.configuration
        config?.showsActivityIndicator = !enabled
        saveButton.configuration = config
    }

    /// photoImageView에 이미지가 없는 등 예외 상황을 위한 대체 경로.
    private func legacyRenderCompositeImage() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = traitCollection.displayScale
        let renderer = UIGraphicsImageRenderer(bounds: stickerCanvas.bounds, format: format)
        return renderer.pngData { _ in
            let offsetRect = CGRect(
                origin: CGPoint(x: -stickerCanvas.frame.minX, y: -stickerCanvas.frame.minY),
                size: photoImageView.bounds.size
            )
            photoImageView.drawHierarchy(in: offsetRect, afterScreenUpdates: true)
        }
    }

    func markChangesSaved() {
        hasUnsavedChanges = false
    }

    // MARK: - Sticker Management

    private func bindStickerCallbacks(_ sticker: TextStickerView) {
        sticker.onTap = { [weak self, weak sticker] in
            guard let sticker else { return }
            self?.showTextEditOverlay(editing: sticker)
        }
        sticker.onPanStateChanged = { [weak self, weak sticker] state in
            guard let self, let sticker else { return }
            self.handleStickerPan(sticker, state: state)
        }
        sticker.onTransformChanged = { [weak self] in
            self?.markChanged()
        }
    }

    private func markChanged() {
        hasUnsavedChanges = true
    }

    // MARK: - Trash Zone

    private func handleStickerPan(_ sticker: TextStickerView, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            showTrashView()
            updateTrashHighlight(for: sticker)
        case .changed:
            updateTrashHighlight(for: sticker)
            markChanged()
        case .ended:
            if isStickerOverTrash(sticker) { deleteSticker(sticker) }
            hideTrashView()
        case .cancelled, .failed:
            hideTrashView()
        default:
            break
        }
    }

    private func isStickerOverTrash(_ sticker: TextStickerView) -> Bool {
        guard !trashView.isHidden else { return false }
        let stickerCenter = stickerCanvas.convert(sticker.center, to: self)
        return trashView.frame.insetBy(dx: -12, dy: -12).contains(stickerCenter)
    }

    private func updateTrashHighlight(for sticker: TextStickerView) {
        let over = isStickerOverTrash(sticker)
        guard over != isTrashHighlighted else { return }
        isTrashHighlighted = over
        UIView.animate(withDuration: 0.15) {
            self.trashView.transform = over ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            self.trashView.backgroundColor = over
                ? UIColor.systemRed.withAlphaComponent(0.9)
                : UIColor.black.withAlphaComponent(0.55)
        }
    }

    private func showTrashView() {
        trashView.isHidden = false
        bringSubviewToFront(trashView)
        UIView.animate(withDuration: 0.2) { self.trashView.alpha = 1 }
    }

    private func hideTrashView() {
        isTrashHighlighted = false
        UIView.animate(withDuration: 0.2, animations: {
            self.trashView.alpha = 0
            self.trashView.transform = .identity
            self.trashView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        }) { _ in
            self.trashView.isHidden = true
        }
    }

    private func deleteSticker(_ sticker: TextStickerView) {
        markChanged()
        UIView.animate(withDuration: 0.2, animations: {
            sticker.alpha = 0
            sticker.transform = sticker.transform.scaledBy(x: 0.1, y: 0.1)
        }) { _ in
            sticker.removeFromSuperview()
        }
    }

    // MARK: - Text Edit Overlay

    private func showTextEditOverlay(editing sticker: TextStickerView?) {
        editingSticker = sticker
        if let s = sticker {
            currentTextColor = s.stickerColor
            currentFontSize = s.stickerFontSize
        }

        let overlay = buildOverlayContainer()
        let (closeBtn, doneBtn) = addOverlayTopBar(to: overlay)
        let controlsBar = addOverlayControlsBar(to: overlay)
        addOverlayTextView(to: overlay, below: closeBtn, above: controlsBar, editing: sticker)

        closeBtn.addTarget(self, action: #selector(dismissTextOverlay), for: .touchUpInside)
        doneBtn.addTarget(self, action: #selector(commitTextOverlay), for: .touchUpInside)

        overlay.alpha = 0
        addSubview(overlay)
        overlay.layoutIfNeeded()

        if let sticker, let tv = overlayTextView {
            sticker.isHidden = true
            tv.transform = stickerToTextViewTransform(sticker: sticker, textView: tv, in: overlay)
        }
        [closeBtn, doneBtn].forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: -8)
        }
        controlsBar.alpha = 0
        controlsBar.transform = CGAffineTransform(translationX: 0, y: 24)

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut], animations: {
            overlay.alpha = 1
            self.overlayTextView?.transform = .identity
            closeBtn.alpha = 1
            closeBtn.transform = .identity
            doneBtn.alpha = 1
            doneBtn.transform = .identity
            controlsBar.alpha = 1
            controlsBar.transform = .identity
        }, completion: { _ in
            self.overlayTextView?.becomeFirstResponder()
        })
    }

    private func stickerToTextViewTransform(sticker: TextStickerView, textView: UITextView, in overlay: UIView) -> CGAffineTransform {
        let savedTransform = sticker.transform
        sticker.transform = .identity
        let srcRect = sticker.convert(sticker.bounds, to: overlay)
        sticker.transform = savedTransform

        let fitting = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let textW = max(fitting.width, 1)
        let textH = max(fitting.height, 1)
        let dstRect = CGRect(
            x: textView.frame.midX - textW / 2,
            y: textView.frame.minY,
            width: textW,
            height: textH
        )

        let scale = max(srcRect.width / dstRect.width, srcRect.height / dstRect.height)
        let tvCenter = CGPoint(x: textView.frame.midX, y: textView.frame.midY)
        let scaledDstCenter = CGPoint(
            x: tvCenter.x + scale * (dstRect.midX - tvCenter.x),
            y: tvCenter.y + scale * (dstRect.midY - tvCenter.y)
        )
        let tx = srcRect.midX - scaledDstCenter.x
        let ty = srcRect.midY - scaledDstCenter.y
        return CGAffineTransform(translationX: tx, y: ty).scaledBy(x: scale, y: scale)
    }

    private func buildOverlayContainer() -> UIView {
        let overlay = UIView(frame: bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        overlayView = overlay
        return overlay
    }

    private func addOverlayTopBar(to overlay: UIView) -> (close: UIButton, done: UIButton) {
        let closeBtn = makeOverlayIconButton(systemName: "xmark")
        let doneBtn = makeOverlayTextButton(title: L.buttonDone)
        overlayCloseButton = closeBtn
        overlayDoneButton = doneBtn
        overlay.addSubview(closeBtn)
        overlay.addSubview(doneBtn)
        closeBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalTo(overlay.safeAreaLayoutGuide).inset(10)
            make.size.equalTo(36)
        }
        doneBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(closeBtn)
        }
        return (closeBtn, doneBtn)
    }

    private func addOverlayControlsBar(to overlay: UIView) -> UIView {
        let controlsBar = makeControlsBar()
        overlayControlsBar = controlsBar
        overlay.addSubview(controlsBar)
        controlsBar.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(88)
        }
        return controlsBar
    }

    private func addOverlayTextView(to overlay: UIView, below topAnchor: UIView, above bottomAnchor: UIView, editing sticker: TextStickerView?) {
        let tv = makeOverlayTextView()
        tv.delegate = self
        if let s = sticker { tv.text = s.stickerText }
        GlyphKerning.apply(to: tv.textStorage)
        overlayTextView = tv
        overlay.addSubview(tv)
        let maxWidth = min(overlay.bounds.width - 40, 300.0)
        tv.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(maxWidth)
            make.centerY.equalTo(overlay.safeAreaLayoutGuide).offset(-30).priority(.low)
            make.top.greaterThanOrEqualTo(topAnchor.snp.bottom).offset(16)
            make.bottom.lessThanOrEqualTo(bottomAnchor.snp.top).offset(-12)
        }
    }

    @objc private func dismissTextOverlay() {
        endEditing(true)
        animateOverlayOut(target: editingSticker)
        editingSticker = nil
    }

    @objc private func commitTextOverlay() {
        guard let tv = overlayTextView,
              let text = tv.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            dismissTextOverlay()
            return
        }

        endEditing(true)

        let target: TextStickerView
        if let existing = editingSticker {
            if existing.stickerText != text ||
                existing.stickerFontSize != currentFontSize ||
                !existing.stickerColor.isEqual(currentTextColor) {
                markChanged()
            }
            existing.configure(text: text, fontSize: currentFontSize, color: currentTextColor)
            target = existing
        } else {
            let sticker = TextStickerView(text: text, fontSize: currentFontSize, color: currentTextColor)
            stickerCanvas.addSubview(sticker)
            sticker.center = CGPoint(x: stickerCanvas.bounds.midX, y: stickerCanvas.bounds.midY)
            sticker.isHidden = true
            bindStickerCallbacks(sticker)
            target = sticker
            actionPublisher.send(.textStickerAdded)
            markChanged()
        }

        animateOverlayOut(target: target)
        editingSticker = nil
    }

    private func animateOverlayOut(target: TextStickerView?) {
        guard let overlay = overlayView else { return }
        overlay.layoutIfNeeded()
        let closeBtn = overlayCloseButton
        let doneBtn = overlayDoneButton
        let controlsBar = overlayControlsBar

        if let target, let tv = overlayTextView {
            let endTransform = stickerToTextViewTransform(sticker: target, textView: tv, in: overlay)
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn], animations: {
                tv.transform = endTransform
                closeBtn?.alpha = 0
                closeBtn?.transform = CGAffineTransform(translationX: 0, y: -8)
                doneBtn?.alpha = 0
                doneBtn?.transform = CGAffineTransform(translationX: 0, y: -8)
                controlsBar?.alpha = 0
                controlsBar?.transform = CGAffineTransform(translationX: 0, y: 24)
                overlay.alpha = 0
            }, completion: { _ in
                target.isHidden = false
                tv.transform = .identity
                overlay.removeFromSuperview()
            })
        } else {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn], animations: {
                closeBtn?.alpha = 0
                closeBtn?.transform = CGAffineTransform(translationX: 0, y: -8)
                doneBtn?.alpha = 0
                doneBtn?.transform = CGAffineTransform(translationX: 0, y: -8)
                controlsBar?.alpha = 0
                controlsBar?.transform = CGAffineTransform(translationX: 0, y: 24)
                overlay.alpha = 0
            }) { _ in
                overlay.removeFromSuperview()
            }
        }
    }

    // MARK: - Overlay UI Factories

    private func makeOverlayTextView() -> UITextView {
        let storage = NSTextStorage()
        let layoutManager = GlyphLayoutManager()
        let container = NSTextContainer()
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)

        let tv = UITextView(frame: .zero, textContainer: container)
        tv.font = .custom(size: currentFontSize)
        tv.textColor = currentTextColor
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.textAlignment = .center
        tv.tintColor = .white
        return tv
    }

    private func makeOverlayIconButton(systemName: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        btn.layer.cornerRadius = 18
        btn.tintColor = .white
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: cfg), for: .normal)
        return btn
    }

    private func makeOverlayTextButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.bodyHeader,
                .foregroundColor: UIColor.white
            ])
        )
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        btn.configuration = config
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        btn.layer.cornerRadius = 16
        return btn
    }

    private func makeControlsBar() -> UIView {
        let bar = UIView()
        bar.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let colorStack = makeColorStack()
        let sizeSegment = makeSizeSegment()
        bar.addSubview(sizeSegment)
        bar.addSubview(colorStack)
        sizeSegment.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(8)
            make.width.equalTo(140)
        }
        colorStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(14)
        }
        return bar
    }

    private func makeColorStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        colorChips = []
        for (i, color) in Self.stickerColors.enumerated() {
            let chip = UIButton(type: .custom)
            chip.backgroundColor = color
            chip.layer.cornerRadius = 13
            chip.tag = i
            chip.addTarget(self, action: #selector(colorChipTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(chip)
            chip.snp.makeConstraints { $0.size.equalTo(26) }
            colorChips.append(chip)
        }
        updateChipSelection(Self.stickerColors.firstIndex(of: currentTextColor) ?? 0)
        return stack
    }

    /// 선택된 색상 칩만 강조 테두리를 표시한다.
    private func updateChipSelection(_ index: Int) {
        for (i, chip) in colorChips.enumerated() {
            let color = Self.stickerColors[i]
            if i == index {
                chip.layer.borderWidth = 2.5
                // 흰색 칩 위에서는 흰 링이 보이지 않으므로 회색 링으로 대체한다.
                chip.layer.borderColor = (color == .white) ? UIColor.gray.cgColor : UIColor.white.cgColor
            } else {
                chip.layer.borderWidth = (color == .white || color == .black) ? 1 : 0
                chip.layer.borderColor = UIColor.gray.cgColor
            }
        }
    }

    private func makeSizeSegment() -> UISegmentedControl {
        let sc = UISegmentedControl(items: [L.sizeSmall, L.sizeMedium, L.sizeLarge])
        sc.selectedSegmentIndex = Self.fontSizes.firstIndex(of: currentFontSize) ?? 1
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        sc.selectedSegmentTintColor = .white
        sc.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        sc.addTarget(self, action: #selector(sizeControlChanged(_:)), for: .valueChanged)
        return sc
    }

    // MARK: - Overlay Control Handlers

    @objc private func colorChipTapped(_ sender: UIButton) {
        currentTextColor = Self.stickerColors[sender.tag]
        updateChipSelection(sender.tag)
        overlayTextView?.textColor = currentTextColor
        applyAttributeToOverlayText(.foregroundColor, value: currentTextColor)
    }

    @objc private func sizeControlChanged(_ sender: UISegmentedControl) {
        currentFontSize = Self.fontSizes[sender.selectedSegmentIndex]
        guard let tv = overlayTextView else { return }
        tv.font = .custom(size: currentFontSize)
        if applyAttributeToOverlayText(.font, value: UIFont.custom(size: currentFontSize)) {
            GlyphKerning.apply(to: tv.textStorage)
        }
    }

    /// 오버레이 텍스트뷰의 전체 범위에 속성을 적용한다. 텍스트가 비어 있으면 false 를 반환한다.
    @discardableResult
    private func applyAttributeToOverlayText(_ key: NSAttributedString.Key, value: Any) -> Bool {
        guard let tv = overlayTextView, let text = tv.text, !text.isEmpty else { return false }
        tv.textStorage.addAttribute(key, value: value,
                                    range: NSRange(location: 0, length: (text as NSString).length))
        return true
    }

    // MARK: - Keyboard

    private func setupKeyboardObservers() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in self?.handleKeyboardChange(notification) }
            .store(in: &cancellables)
    }

    private func handleKeyboardChange(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let overlay = overlayView,
              let controlsBar = overlayControlsBar else { return }

        let inset = notification.name == UIResponder.keyboardWillShowNotification ? keyboardFrame.height : 0
        UIView.animate(withDuration: duration) {
            controlsBar.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(inset)
            }
            overlay.layoutIfNeeded()
        }
    }
}

// MARK: - UITextViewDelegate

extension PhotoDecorateView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard textView === overlayTextView else { return }
        GlyphKerning.apply(to: textView.textStorage)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PhotoDecorateView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
