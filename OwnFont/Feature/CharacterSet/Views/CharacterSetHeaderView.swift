//
//  CharacterSetHeaderView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class CharacterSetHeaderView: UIView {
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 6
        return sv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = L.characterSetTitle
        label.font = .cardTitle
        label.textColor = .textTitle
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = L.characterSetSubtitle
        label.font = .caption
        label.textColor = .textHint
        label.numberOfLines = 0
        return label
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
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
