//
//  NativeAdCardView.swift
//  OwnFont
//

import UIKit
import SnapKit
import GoogleMobileAds

final class NativeAdCardView: NativeAdView {

    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        view.backgroundColor = .surfaceSecondary
        view.clipsToBounds = true
        return view
    }()

    private let adIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        return iv
    }()

    private let infoStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 3
        return sv
    }()

    private let adHeadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .cardHeader
        label.textColor = .textTitle
        label.numberOfLines = 1
        return label
    }()

    private let adBodyLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textHint
        label.numberOfLines = 1
        return label
    }()

    private let adBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .amberLight
        view.layer.cornerRadius = 12
        return view
    }()

    private let adBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = "광고"
        label.font = .badge
        label.textColor = .amberDark
        label.textAlignment = .center
        return label
    }()

    private let adCallToActionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .badge
        btn.setTitleColor(.primary, for: .normal)
        btn.isUserInteractionEnabled = false
        return btn
    }()

    private let topRowStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .center
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindAdViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bindAdViews()
    }

    private func setupUI() {
        backgroundColor = .surface
        layer.cornerRadius = 16

        iconContainer.addSubview(adIconImageView)
        adIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(36)
        }
        iconContainer.snp.makeConstraints { make in
            make.size.equalTo(44)
        }

        infoStackView.addArrangedSubview(adHeadlineLabel)
        infoStackView.addArrangedSubview(adBodyLabel)

        adBadgeView.addSubview(adBadgeLabel)
        adBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
        }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        topRowStackView.addArrangedSubview(iconContainer)
        topRowStackView.addArrangedSubview(infoStackView)
        topRowStackView.addArrangedSubview(spacer)
        topRowStackView.addArrangedSubview(adBadgeView)
        topRowStackView.addArrangedSubview(adCallToActionButton)

        addSubview(topRowStackView)
        topRowStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    private func bindAdViews() {
        headlineView = adHeadlineLabel
        bodyView = adBodyLabel
        iconView = adIconImageView
        callToActionView = adCallToActionButton
    }

    func configure(with nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        adHeadlineLabel.text = nativeAd.headline
        adBodyLabel.text = nativeAd.body
        adIconImageView.image = nativeAd.icon?.image
        adCallToActionButton.setTitle(nativeAd.callToAction, for: .normal)
    }
}
