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

    private static let stickerColors: [UIColor] = [
        .white, .black, .systemYellow, .systemPink, .systemCyan, .systemOrange
    ]
    private static let fontSizes: [CGFloat] = [24, 36, 52]

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
        return iv
    }()

    private let stickerCanvas: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.clipsToBounds = false
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(textButton)
        navBarView.addSubview(saveButton)
        view.addSubview(photoImageView)
        view.addSubview(stickerCanvas)

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

        let sharedConstraints = { (make: ConstraintMaker) in
            make.top.equalTo(self.navBarView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(20)
        }
        photoImageView.snp.makeConstraints(sharedConstraints)
        stickerCanvas.snp.makeConstraints(sharedConstraints)
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

    // MARK: - Text Edit Overlay (TBD)

    private func showTextEditOverlay(editing sticker: TextStickerView?) {}

    // MARK: - Save

    private func renderAndSave() {
        deselectAllStickers()
        let pngData = renderCompositeImage()
        saveToPhotoLibrary(pngData)
    }

    private func renderCompositeImage() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(bounds: photoImageView.bounds, format: format)
        return renderer.pngData { _ in
            photoImageView.drawHierarchy(in: photoImageView.bounds, afterScreenUpdates: true)
            stickerCanvas.drawHierarchy(in: stickerCanvas.bounds, afterScreenUpdates: true)
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
