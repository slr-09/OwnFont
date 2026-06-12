//
//  InstagramShareButton.swift
//  OwnFont
//

import UIKit
import SnapKit

/// 인스타그램 브랜드 그라데이션 + 에셋 로고 + "스토리" 라벨로 구성된 공유 버튼.
final class InstagramShareButton: UIControl {

    private let backgroundView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        return v
    }()

    private let gradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(hex: "FEDA77").cgColor,
            UIColor(hex: "F58529").cgColor,
            UIColor(hex: "DD2A7B").cgColor,
            UIColor(hex: "8134AF").cgColor,
            UIColor(hex: "515BD4").cgColor
        ]
        l.startPoint = CGPoint(x: 0, y: 0)
        l.endPoint = CGPoint(x: 1, y: 1)
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "insta")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = L.instagramStory
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.isUserInteractionEnabled = false
        return l
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(backgroundView)
        backgroundView.layer.addSublayer(gradientLayer)
        addSubview(iconView)
        addSubview(titleLabel)

        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(5)
            make.trailing.equalToSuperview().inset(11)
            make.centerY.equalToSuperview()
        }

        accessibilityLabel = L.instagramShareAccessibility
        accessibilityTraits = .button
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = backgroundView.bounds
        backgroundView.layer.cornerRadius = bounds.height / 2
    }

    // 탭 피드백
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.7 : 1.0
            }
        }
    }
}
