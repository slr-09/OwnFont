//
//  CharacterSetViewController.swift
//  OwnFont
//
//  Created by Claude
//

import UIKit
import SnapKit

final class CharacterSetViewController: UIViewController {
    private let scrollView = UIScrollView()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        return sv
    }()

    private let headerView = CharacterSetHeaderView()

    private let cardListStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 10
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let categories = Array(CharacterCategory.allCases)
        guard tag < categories.count else { return }
        let vc = CharacterWritingViewController(category: categories[tag])
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .background
        navigationController?.navigationBar.isHidden = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(cardListStackView)

        CharacterCategory.allCases.enumerated().forEach { index, category in
            let cardView = CategoryCardView()
            cardView.configure(with: category, completedCount: 0)
            cardView.tag = index
            cardView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
            cardView.addGestureRecognizer(tap)
            cardListStackView.addArrangedSubview(cardView)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            make.width.equalToSuperview().offset(-40)
        }
    }
}
