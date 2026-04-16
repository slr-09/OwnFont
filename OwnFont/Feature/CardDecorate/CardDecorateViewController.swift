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
        let card = contentView.memoCardView
        let renderer = UIGraphicsImageRenderer(bounds: card.bounds)
        let image = renderer.image { ctx in
            card.layer.render(in: ctx.cgContext)
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(
                        image, self,
                        #selector(self.imageSaved(_:didFinishSavingWithError:contextInfo:)),
                        nil
                    )
                default:
                    self.showAlert(title: "저장 실패", message: "사진 접근 권한이 필요합니다.\n설정에서 허용해주세요.")
                }
            }
        }
    }

    @objc private func imageSaved(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        if let error {
            showAlert(title: "저장 실패", message: error.localizedDescription)
        } else {
            showAlert(title: "저장 완료", message: "카드가 사진 앱에 저장됐어요!")
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
