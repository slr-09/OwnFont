//
//  CardHomeViewController.swift
//  OwnFont
//

import GoogleMobileAds
import PhotosUI
import UIKit
import SnapKit
import UniformTypeIdentifiers

final class CardHomeViewController: UIViewController {

    // MARK: - Subviews

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = L.tabBarDecorate
        l.font = .cardTitle
        l.textColor = .textTitle
        return l
    }()

    private let settingsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .surfaceSecondary
        btn.layer.cornerRadius = 18
        btn.tintColor = .textPrimary
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "gearshape", withConfiguration: cfg), for: .normal)
        return btn
    }()

    private let bannerView: BannerView = {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = Bundle.main.infoDictionary?["AdMobBannerID"] as? String
        return banner
    }()

    private let memoCard = CardHomeViewController.makeEntryCard(
        iconName: "doc.text",
        accentColor: .indigo,
        subtleColor: .indigoSubtle,
        title: L.cardHomeMemoTitle,
        subtitle: L.cardHomeMemoSubtitle
    )

    private let photoCard = CardHomeViewController.makeEntryCard(
        iconName: "photo.on.rectangle.angled",
        accentColor: .primary,
        subtleColor: .primarySubtle,
        title: L.photoDecorateTitle,
        subtitle: L.cardHomePhotoSubtitle
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupLayout()
        setupActions()
        setupBanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(settingsButton)
        view.addSubview(memoCard)
        view.addSubview(photoCard)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.equalToSuperview().inset(20)
        }
        settingsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(36)
        }
        memoCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }
        photoCard.snp.makeConstraints { make in
            make.top.equalTo(memoCard.snp.bottom).offset(14)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }
    }

    private func setupBanner() {
        bannerView.rootViewController = self
        view.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
        }
        bannerView.load(Request())
    }

    // MARK: - Actions

    private func setupActions() {
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        addCardGesture(to: memoCard) { [weak self] in
            AnalyticsManager.shared.log(.decorateMemoOpened)
            let vc = CardDecorateViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        addCardGesture(to: photoCard) { [weak self] in
            AnalyticsManager.shared.log(.decoratePhotoOpened)
            self?.presentPhotoPicker()
        }
    }

    @objc private func settingsTapped() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    private func addCardGesture(to card: UIView, onTap: @escaping () -> Void) {
        let gesture = CardTapGesture(target: self, action: #selector(handleCardPress(_:)))
        gesture.onTap = onTap
        card.addGestureRecognizer(gesture)
    }

    @objc private func handleCardPress(_ gesture: CardTapGesture) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.15) {
                gesture.view?.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }
        case .ended:
            // 제스처가 리셋된 뒤(완료 콜백)에는 location(in:) 값이 불안정하므로
            // .ended 시점에 카드 내부 여부를 동기적으로 계산해 둔다. (iPad 전환 누락 원인)
            let isInsideCard = gesture.view.map { $0.bounds.contains(gesture.location(in: $0)) } ?? false
            UIView.animate(withDuration: 0.15) {
                gesture.view?.transform = .identity
            } completion: { _ in
                if isInsideCard { gesture.onTap?() }
            }
        case .cancelled, .failed:
            UIView.animate(withDuration: 0.15) {
                gesture.view?.transform = .identity
            }
        default:
            break
        }
    }

    // MARK: - Photo Picker

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        // 호환성을 위해 HEIC 원본을 JPEG로 재인코딩(손실 압축)하지 않도록,
        // Photos 앱에 보이는 원본 그대로의 표현을 요청한다.
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Factory

    private static func makeEntryCard(
        iconName: String,
        accentColor: UIColor,
        subtleColor: UIColor,
        title: String,
        subtitle: String
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = subtleColor
        card.layer.cornerRadius = 20
        card.layer.shadowColor = accentColor.cgColor
        card.layer.shadowOpacity = 0.1
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8

        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: cfg))
        iconView.tintColor = accentColor

        let chevronCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: chevronCfg))
        chevron.tintColor = .textHint

        let topRow = UIView()
        topRow.addSubview(iconView)
        topRow.addSubview(chevron)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .bodyHeader
        titleLabel.textColor = .textPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .body
        subtitleLabel.textColor = .iconInactive

        card.addSubview(topRow)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        topRow.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(18)
            make.height.equalTo(24)
        }
        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        chevron.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(18)
            make.bottom.equalTo(subtitleLabel.snp.top).offset(-4)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(18)
        }

        return card
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CardHomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // dismiss 애니메이션이 끝나기 전에 토스트를 띄우면 탭바가 window 계층에
        // 아직 재편입되지 않아 SnapKit 제약이 공통 조상을 찾지 못해 크래시한다.
        // 반드시 dismiss 완료 후에 후속 처리를 진행한다.
        picker.dismiss(animated: true) { [weak self] in
            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                ToastManager.show(L.toastPhotoLoadFailed, style: .error)
                return
            }

            // loadObject(ofClass: UIImage.self)는 원본 대신 저해상도 프록시 이미지를
            // 반환할 수 있어, Apple 권장 방식대로 원본 파일을 직접 읽어 화질 저하를 방지한다.
            // iCloud 원본 다운로드 실패 등으로 실패할 수 있으므로 실패 시 토스트로 안내한다.
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, _ in
                guard let url,
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        ToastManager.show(L.toastPhotoLoadFailed, style: .error)
                    }
                    return
                }
                DispatchQueue.main.async {
                    let vc = PhotoDecorateViewController(photo: image)
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

// MARK: - CardTapGesture

private final class CardTapGesture: UILongPressGestureRecognizer {
    var onTap: (() -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        minimumPressDuration = 0
    }
}
