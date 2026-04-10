//
//  CategoryCardView.swift
//  OwnFont
//
//  Created by Claude
//

import UIKit
import SnapKit

final class CategoryCardView: UIView {
    private let topRowStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .center
        return sv
    }()

    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let infoStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 3
        return sv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .cardHeader
        label.textColor = .textTitle
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textHint
        label.numberOfLines = 1
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .surfaceSecondary
        view.layer.cornerRadius = 12
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.text = "시작 전"
        label.font = .badge
        label.textColor = .textHint
        label.textAlignment = .center
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .borderLight
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let progressBarBg: UIView = {
        let view = UIView()
        view.backgroundColor = .surfaceSecondary
        view.layer.cornerRadius = 3
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .surface
        layer.cornerRadius = 16

        // Icon container
        addSubview(topRowStackView)
        topRowStackView.addArrangedSubview(iconContainer)

        iconContainer.addSubview(iconImageView)
        iconContainer.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        // Info stack
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(subtitleLabel)
        topRowStackView.addArrangedSubview(infoStackView)

        // Flexible spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        topRowStackView.addArrangedSubview(spacer)

        // Badge
        badgeView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
        }
        topRowStackView.addArrangedSubview(badgeView)

        // Chevron
        topRowStackView.addArrangedSubview(chevronImageView)
        chevronImageView.snp.makeConstraints { make in
            make.size.equalTo(16)
        }

        // Progress bar
        addSubview(progressBarBg)

        topRowStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        progressBarBg.snp.makeConstraints { make in
            make.top.equalTo(topRowStackView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(6)
        }
    }

    func configure(with category: CharacterCategory, completedCount: Int) {
        titleLabel.text = category.title
        subtitleLabel.text = category.subtitle(completedCount: completedCount)
        iconImageView.image = UIImage(systemName: category.iconName)
        iconImageView.tintColor = category.iconColor
        iconContainer.backgroundColor = category.iconBgColor
    }
}
