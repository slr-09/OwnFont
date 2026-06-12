//
//  CharacterSetViewController.swift
//  OwnFont
//
//  Created by Claude
//

import Combine
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

    private let editorButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .primary
        btn.layer.cornerRadius = 14
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            L.characterSetEditorButton,
            attributes: AttributeContainer([
                .font: UIFont.cardHeader,
                .foregroundColor: UIColor.white
            ])
        )
        config.image = UIImage(systemName: "pencil.and.scribble")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        )
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        config.baseForegroundColor = .white
        btn.configuration = config
        return btn
    }()

    private let cardListStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 10
        return sv
    }()

    private var cardViews: [CategoryCardView] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCompletionCounts()
        bindStore()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Actions

    @objc private func editorButtonTapped() {
        let vc = TextEditorViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let categories = Array(CharacterCategory.allCases)
        guard tag < categories.count else { return }
        let vc: UIViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            vc = CharacterWritingGridViewController(category: categories[tag])
        } else {
            vc = CharacterWritingViewController(category: categories[tag])
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .background
        navigationController?.navigationBar.isHidden = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(editorButton)
        contentStackView.addArrangedSubview(cardListStackView)

        editorButton.addTarget(self, action: #selector(editorButtonTapped), for: .touchUpInside)

        CharacterCategory.allCases.enumerated().forEach { index, category in
            let cardView = CategoryCardView()
            cardView.tag = index
            cardView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
            cardView.addGestureRecognizer(tap)
            cardListStackView.addArrangedSubview(cardView)
            cardViews.append(cardView)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            make.width.equalToSuperview().offset(-40)
        }
    }

    // MARK: - Bind

    private func bindStore() {
        GlyphStore.shared.glyphsDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateCompletionCounts()
            }
            .store(in: &cancellables)
    }

    // MARK: - Update

    private func updateCompletionCounts() {
        var totalCompleted = 0
        CharacterCategory.allCases.enumerated().forEach { index, category in
            let completedCount = category.characters.filter {
                GlyphStore.shared.hasGlyph(for: $0)
            }.count
            totalCompleted += completedCount
            cardViews[index].configure(with: category, completedCount: completedCount)
        }
        editorButton.isHidden = totalCompleted == 0
    }
}
