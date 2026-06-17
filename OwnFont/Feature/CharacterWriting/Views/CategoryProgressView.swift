//
//  CategoryProgressView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class CategoryProgressView: UIView {

    private let progressTrack: UIView = {
        let v = UIView()
        v.backgroundColor = .borderLight
        v.layer.cornerRadius = 3
        v.clipsToBounds = true
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.backgroundColor = .primary
        v.layer.cornerRadius = 3
        return v
    }()

    private let progressLabel: UILabel = {
        let l = UILabel()
        l.font = .caption
        l.textColor = .textHint
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        progressTrack.addSubview(progressFill)
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(progressTrack).multipliedBy(0)
        }

        let row = UIStackView(arrangedSubviews: [progressTrack, progressLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        addSubview(row)

        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        progressTrack.snp.makeConstraints { make in
            make.height.equalTo(6)
        }
    }

    func update(completed: Int, total: Int) {
        let ratio = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        let percent = total > 0 ? Int(ratio * 100) : 0
        progressLabel.text = L.writingProgress(percent: percent)
        progressFill.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(progressTrack).multipliedBy(ratio)
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.progressTrack.layoutIfNeeded()
        }
    }
}
