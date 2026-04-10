//
//  CharacterSetHeaderView.swift
//  OwnFont
//
//  Created by Claude
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
        label.text = "어떤 글자를 쓸까요?"
        label.font = .cardTitle
        label.textColor = .textTitle
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "세트를 탭하면 바로 쓰기를 시작해요"
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
