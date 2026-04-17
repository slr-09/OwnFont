//
//  CardHomeViewController.swift
//  OwnFont
//

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

    private let memoCard: UIView = {
        let v = UIView()
        v.backgroundColor = .indigoSubtle
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.indigo.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let cardIcon: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "doc.text", withConfiguration: cfg))
        iv.tintColor = .indigo
        return iv
    }()

    private let chevronIcon: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: cfg))
        iv.tintColor = .textHint
        return iv
    }()

    private let cardTitle: UILabel = {
        let l = UILabel()
        l.text = "메모지 꾸미기"
        l.font = .bodyHeader
        l.textColor = .textPrimary
        return l
    }()

    private let cardSubtitle: UILabel = {
        let l = UILabel()
        l.text = "예쁜 메모지에 글씨를 적어보세요"
        l.font = .body
        l.textColor = .iconInactive
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupLayout()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(memoCard)

        let topRow = UIView()
        memoCard.addSubview(topRow)
        topRow.addSubview(cardIcon)
        topRow.addSubview(chevronIcon)
        memoCard.addSubview(cardTitle)
        memoCard.addSubview(cardSubtitle)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.equalToSuperview().inset(20)
        }

        memoCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(160)
        }

        topRow.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(18)
            make.height.equalTo(24)
        }
        cardIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        chevronIcon.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(18)
        }

        cardTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(18)
            make.bottom.equalTo(cardSubtitle.snp.top).offset(-4)
        }
        cardSubtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(18)
        }
    }

    // MARK: - Actions

    private func setupActions() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(memoCardPressed(_:)))
        longPress.minimumPressDuration = 0
        memoCard.addGestureRecognizer(longPress)
    }

    @objc private func memoCardPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.15) {
                self.memoCard.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }
        case .ended:
            UIView.animate(withDuration: 0.15) {
                self.memoCard.transform = .identity
            } completion: { _ in
                let point = gesture.location(in: self.memoCard)
                if self.memoCard.bounds.contains(point) {
                    let vc = CardDecorateViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        case .cancelled, .failed:
            UIView.animate(withDuration: 0.15) {
                self.memoCard.transform = .identity
            }
        default:
            break
        }
    }
}
