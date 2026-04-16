//
//  CardDecorateViewController.swift
//  OwnFont
//

import Combine
import Photos
import UIKit

final class CardDecorateViewController: UIViewController {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()

    private var contentView: CardDecorateView {
        view as! CardDecorateView
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = CardDecorateView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindCallbacks()
        setupInitialCard()
        setupDismissKeyboardGesture()
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
                case .saveImage:
                    renderCardAsImage()
                case .mainTextChanged(let text):
                    contentView.memoCardView.configure(mainText: text)
                case .subTextChanged(let text):
                    contentView.memoCardView.configure(subText: text)
                case .backgroundColorSelected(let bg, let stroke):
                    contentView.memoCardView.setBackground(bg, stroke: stroke)
                case .mainTextToggled(let isOn):
                    contentView.memoCardView.setMainVisible(isOn)
                case .subTextToggled(let isOn):
                    contentView.memoCardView.setSubVisible(isOn)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Setup

    private func setupInitialCard() {
        contentView.memoCardView.configure(
            date: DateFormatManager.shared.formattedDate(),
            mainText: "",
            subText: ""
        )
    }

    private func setupDismissKeyboardGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        contentView.dismissKeyboard()
    }

    // MARK: - Image Save

    private func renderCardAsImage() {
        // png로 변환
        let card = contentView.memoCardView
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(bounds: card.bounds, format: format)
        let pngData = renderer.pngData { ctx in
            card.layer.render(in: ctx.cgContext)
        }

        requestPhotoAuthorization { [weak self] in
            self?.savePNGToPhotoLibrary(pngData)
        }
    }

    private func requestPhotoAuthorization(authorized: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    authorized()
                default:
                    self?.showAlert(title: "저장 실패", message: "사진 접근 권한이 필요합니다.\n설정에서 허용해주세요.")
                }
            }
        }
    }

    private func savePNGToPhotoLibrary(_ data: Data) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAlert(title: "저장 실패", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "저장 완료", message: "카드가 사진 앱에 저장됐어요!")
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
