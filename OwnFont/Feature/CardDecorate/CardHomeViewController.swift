//
//  CardHomeViewController.swift
//  OwnFont
//

import GoogleMobileAds
import PhotosUI
import UIKit
import SnapKit

final class CardHomeViewController: UIViewController {

    // MARK: - Subviews

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "꾸미기"
        l.font = .cardTitle
        l.textColor = .textTitle
        return l
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
        title: "메모지 꾸미기",
        subtitle: "예쁜 메모지에 글씨를 적어보세요"
    )

    private let photoCard = CardHomeViewController.makeEntryCard(
        iconName: "photo.on.rectangle.angled",
        accentColor: .primary,
        subtleColor: .primarySubtle,
        title: "사진 꾸미기",
        subtitle: "사진 위에 나만의 폰트로 글씨를 써보세요"
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
        view.addSubview(memoCard)
        view.addSubview(photoCard)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.equalToSuperview().inset(20)
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
        addCardGesture(to: memoCard) { [weak self] in
            let vc = CardDecorateViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        addCardGesture(to: photoCard) { [weak self] in
            self?.presentPhotoPicker()
        }
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
            UIView.animate(withDuration: 0.15) {
                gesture.view?.transform = .identity
            } completion: { _ in
                guard let card = gesture.view,
                      card.bounds.contains(gesture.location(in: card)) else { return }
                gesture.onTap?()
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
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                let vc = PhotoDecorateViewController(photo: image)
                self.navigationController?.pushViewController(vc, animated: true)
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
