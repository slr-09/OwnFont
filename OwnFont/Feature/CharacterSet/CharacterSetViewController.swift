//
//  CharacterSetViewController.swift
//  OwnFont
//
//  Created by Claude
//

import Combine
import UIKit
import SnapKit
import GoogleMobileAds

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

    private let settingsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .surfaceSecondary
        btn.layer.cornerRadius = 18
        btn.tintColor = .textPrimary
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "gearshape", withConfiguration: cfg), for: .normal)
        return btn
    }()

    private var cardViews: [CategoryCardView] = []
    private var cancellables = Set<AnyCancellable>()
    private var adLoader: AdLoader?
    private var nativeAdCardView: NativeAdCardView?

    private static let nativeAdInsertIndex = 3

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCompletionCounts()
        bindStore()
        loadNativeAd()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Actions

    @objc private func settingsTapped() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

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

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(settingsButton)

        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        settingsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.size.equalTo(36)
        }

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
            make.edges.equalToSuperview()
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            make.width.equalToSuperview().offset(-40)
        }
    }

    // MARK: - Native Ad

    private func loadNativeAd() {
        guard let adUnitID = Bundle.main.object(forInfoDictionaryKey: "AdMobNativeID") as? String else { return }
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: self,
            adTypes: [.native],
            options: [multipleAdsOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    private func insertNativeAdView(_ adView: NativeAdCardView) {
        nativeAdCardView = adView
        let insertIndex = min(Self.nativeAdInsertIndex, cardListStackView.arrangedSubviews.count)
        cardListStackView.insertArrangedSubview(adView, at: insertIndex)
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

// MARK: - GADNativeAdLoaderDelegate

extension CharacterSetViewController: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        let adCardView = NativeAdCardView()
        adCardView.configure(with: nativeAd)
        nativeAd.delegate = self
        insertNativeAdView(adCardView)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {}
}

// MARK: - NativeAdDelegate

extension CharacterSetViewController: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {}
}
