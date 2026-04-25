//
//  PhotoDecorateViewController.swift
//  OwnFont
//

import Photos
import UIKit
import SnapKit

final class PhotoDecorateViewController: UIViewController {

    // MARK: - Properties

    private let photo: UIImage
    private var editingSticker: TextStickerView?
    private weak var overlayTextView: UITextView?
    private var currentTextColor: UIColor = .white
    private var currentFontSize: CGFloat = 36

    private static let stickerColors: [UIColor] = [
        .white, .black, .systemYellow, .systemPink, .systemCyan, .systemOrange
    ]
    private static let fontSizes: [CGFloat] = [24, 36, 52]
    private static let overlayTag = 9999
    private static let controlsBarTag = 9998

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
        l.text = "사진 꾸미기"
        l.font = .cardHeader
        l.textColor = .textPrimary
        return l
    }()

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
            "저장",
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

    // MARK: - Init

    init(photo: UIImage) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupLayout()
        setupActions()
        photoImageView.image = photo
        setupKeyboardObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateStickerCanvasFrame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }

    // MARK: - Layout

    private func updateStickerCanvasFrame() {
        guard let image = photoImageView.image else { return }
        let viewSize = photoImageView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        let imageSize = image.size
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let x = (viewSize.width - scaledSize.width) / 2
        let y = (viewSize.height - scaledSize.height) / 2
        stickerCanvas.frame = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
    }

    private func setupLayout() {
        view.addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(textButton)
        navBarView.addSubview(saveButton)
        view.addSubview(photoImageView)
        photoImageView.addSubview(stickerCanvas)

        navBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
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
        textButton.snp.makeConstraints { make in
            make.trailing.equalTo(saveButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(navBarView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }

    // MARK: - Actions

    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(handleAddText), for: .touchUpInside)

        let canvasTap = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap(_:)))
        stickerCanvas.addGestureRecognizer(canvasTap)
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleSave() {
        renderAndSave()
    }

    @objc private func handleAddText() {
        deselectAllStickers()
        showTextEditOverlay(editing: nil)
    }

    @objc private func handleCanvasTap(_ r: UITapGestureRecognizer) {
        let location = r.location(in: stickerCanvas)
        guard stickerCanvas.hitTest(location, with: nil) === stickerCanvas else { return }
        deselectAllStickers()
    }

    // MARK: - Sticker Management

    private func deselectAllStickers() {
        stickerCanvas.subviews.compactMap { $0 as? TextStickerView }.forEach {
            $0.isStickerSelected = false
        }
    }

    private func addNewSticker(text: String, fontSize: CGFloat, color: UIColor) {
        let sticker = TextStickerView(text: text, fontSize: fontSize, color: color)
        stickerCanvas.addSubview(sticker)
        sticker.center = CGPoint(x: stickerCanvas.bounds.midX, y: stickerCanvas.bounds.midY)
        bindCallbacks(to: sticker)
        animateStickerEntry(sticker)
    }

    private func bindCallbacks(to sticker: TextStickerView) {
        sticker.onDoubleTap = { [weak self, weak sticker] in
            guard let sticker else { return }
            self?.deselectAllStickers()
            self?.showTextEditOverlay(editing: sticker)
        }
        sticker.onDelete = { [weak self] s in
            UIView.animate(withDuration: 0.15, animations: { s.alpha = 0 }) { _ in
                s.removeFromSuperview()
                self?.deselectAllStickers()
            }
        }
    }

    private func animateStickerEntry(_ sticker: TextStickerView) {
        sticker.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
            sticker.transform = .identity
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
        view.addSubview(overlay)
        UIView.animate(withDuration: 0.2) { overlay.alpha = 1 }
        overlayTextView?.becomeFirstResponder()
    }

    private func buildOverlayContainer() -> UIView {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        overlay.tag = Self.overlayTag
        return overlay
    }

    private func addOverlayTopBar(to overlay: UIView) -> (close: UIButton, done: UIButton) {
        let closeBtn = makeOverlayIconButton(systemName: "xmark")
        let doneBtn = makeOverlayTextButton(title: "완료")
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
        controlsBar.tag = Self.controlsBarTag
        overlay.addSubview(controlsBar)
        controlsBar.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        return controlsBar
    }

    private func addOverlayTextView(to overlay: UIView, below topAnchor: UIView, above bottomAnchor: UIView, editing sticker: TextStickerView?) {
        let tv = makeOverlayTextView()
        if let s = sticker { tv.text = s.stickerText }
        overlayTextView = tv
        overlay.addSubview(tv)
        tv.snp.makeConstraints { make in
            make.top.equalTo(topAnchor.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(bottomAnchor.snp.top).offset(-12)
        }
    }

    @objc private func dismissTextOverlay() {
        view.endEditing(true)
        removeTextOverlay()
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

        view.endEditing(true)
        removeTextOverlay()

        if let existing = editingSticker {
            existing.configure(text: text, fontSize: currentFontSize, color: currentTextColor)
        } else {
            addNewSticker(text: text, fontSize: currentFontSize, color: currentTextColor)
        }
        editingSticker = nil
    }

    private func removeTextOverlay() {
        guard let overlay = view.viewWithTag(Self.overlayTag) else { return }
        UIView.animate(withDuration: 0.15, animations: { overlay.alpha = 0 }) { _ in
            overlay.removeFromSuperview()
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
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
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
        bar.addSubview(colorStack)
        bar.addSubview(sizeSegment)
        colorStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        sizeSegment.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(140)
        }
        return bar
    }

    private func makeColorStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        for (i, color) in Self.stickerColors.enumerated() {
            let chip = UIButton(type: .custom)
            chip.backgroundColor = color
            chip.layer.cornerRadius = 13
            chip.layer.borderWidth = (color == .white || color == .black) ? 1 : 0
            chip.layer.borderColor = UIColor.gray.cgColor
            chip.tag = i
            chip.addTarget(self, action: #selector(colorChipTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(chip)
            chip.snp.makeConstraints { $0.size.equalTo(26) }
        }
        return stack
    }

    private func makeSizeSegment() -> UISegmentedControl {
        let sc = UISegmentedControl(items: ["소", "중", "대"])
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
        guard let tv = overlayTextView else { return }
        tv.textColor = currentTextColor
        if let text = tv.text, !text.isEmpty {
            tv.textStorage.addAttribute(.foregroundColor, value: currentTextColor,
                                        range: NSRange(location: 0, length: (text as NSString).length))
        }
    }

    @objc private func sizeControlChanged(_ sender: UISegmentedControl) {
        currentFontSize = Self.fontSizes[sender.selectedSegmentIndex]
        guard let tv = overlayTextView else { return }
        tv.font = .custom(size: currentFontSize)
        if let text = tv.text, !text.isEmpty {
            tv.textStorage.addAttribute(.font, value: UIFont.custom(size: currentFontSize),
                                        range: NSRange(location: 0, length: (text as NSString).length))
        }
    }

    // MARK: - Keyboard

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ n: Notification) {
        guard let keyboardFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let overlay = view.viewWithTag(Self.overlayTag),
              let controlsBar = overlay.viewWithTag(Self.controlsBarTag) else { return }

        let inset = n.name == UIResponder.keyboardWillShowNotification ? keyboardFrame.height : 0
        UIView.animate(withDuration: duration) {
            controlsBar.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(inset)
            }
            overlay.layoutIfNeeded()
        }
    }

    // MARK: - Save

    private func renderAndSave() {
        deselectAllStickers()
        let pngData = renderCompositeImage()
        saveToPhotoLibrary(pngData)
    }

    private func renderCompositeImage() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(bounds: stickerCanvas.bounds, format: format)
        return renderer.pngData { _ in
            let offsetRect = CGRect(
                origin: CGPoint(x: -stickerCanvas.frame.minX, y: -stickerCanvas.frame.minY),
                size: photoImageView.bounds.size
            )
            photoImageView.drawHierarchy(in: offsetRect, afterScreenUpdates: true)
        }
    }

    private func saveToPhotoLibrary(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    self?.showAlert(title: "저장 실패", message: "사진 접근 권한이 필요합니다.\n설정에서 허용해주세요.")
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }) { _, error in
                    DispatchQueue.main.async {
                        ToastManager.show(error != nil ? "저장 실패" : "저장 완료",
                                          style: error != nil ? .error : .success)
                    }
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
