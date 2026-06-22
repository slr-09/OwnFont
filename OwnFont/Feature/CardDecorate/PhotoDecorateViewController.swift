//
//  PhotoDecorateViewController.swift
//  OwnFont
//

import Combine
import Photos
import UIKit

final class PhotoDecorateViewController: UIViewController {

    // MARK: - Properties

    private let photo: UIImage
    private var cancellables = Set<AnyCancellable>()

    private var contentView: PhotoDecorateView { view as! PhotoDecorateView }

    // MARK: - Init

    init(photo: UIImage) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = PhotoDecorateView(photo: photo)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // MARK: - Bind

    private func bindCallbacks() {
        contentView.actionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .back:
                    navigationController?.popViewController(animated: true)
                case .save:
                    AnalyticsManager.shared.log(.decorateSaveImage(source: .photo))
                    renderAndSave()
                case .share:
                    AnalyticsManager.shared.log(.instagramShareTapped(source: .photo))
                    shareToInstagram()
                case .textStickerAdded:
                    AnalyticsManager.shared.log(.decorateTextStickerAdded)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Save & Share

    private func renderAndSave() {
        let pngData = contentView.renderCompositeImage()
        saveToPhotoLibrary(pngData)
    }

    private func shareToInstagram() {
        let pngData = contentView.renderCompositeImage()
        let ok = InstagramStoryShareService.share(pngData: pngData)
        if !ok {
            presentAlert(title: L.alertShareFailedTitle, message: L.alertShareFailedMessage)
        }
    }

    private func saveToPhotoLibrary(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    self?.presentAlert(title: L.alertSaveFailedTitle, message: L.alertSaveFailedMessage)
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }) { _, error in
                    DispatchQueue.main.async {
                        ToastManager.show(error != nil ? L.toastSaveFailed : L.toastSaveCompleted,
                                          style: error != nil ? .error : .success)
                    }
                }
            }
        }
    }

}
