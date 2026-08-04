//
//  InterstitialAdGate.swift
//  OwnFont
//

import GoogleMobileAds
import UIKit

/// 전면 광고의 로드/노출 여부를 중앙에서 관리한다.
///
/// 화면 방문 단위가 아니라 누적 기준으로 노출 여부를 판단해,
/// 여러 번에 나눠서 글자를 쓰는 사용 패턴에서도 결국 노출되도록 하고
/// 쿨다운으로 과다 노출은 막는다.
final class InterstitialAdGate: NSObject {
    static let shared = InterstitialAdGate()
    private override init() { super.init() }

    private let defaults = UserDefaults.standard
    private let writeCountKey = "interstitialAdGate.writeCount"
    private let lastShownAtKey = "interstitialAdGate.lastShownAt"

    /// 마지막 노출 이후 이만큼 새로 글자를 써야 다음 노출 후보가 된다.
    private let minWriteCount = 5
    /// 최소 노출 간격. 짧은 시간에 여러 화면을 오가도 연속 노출되지 않도록 한다.
    private let cooldown: TimeInterval = 5 * 60

    private var ad: InterstitialAd?
    private var isLoading = false
    private var dismissHandler: (() -> Void)?

    private var writeCount: Int {
        get { defaults.integer(forKey: writeCountKey) }
        set { defaults.set(newValue, forKey: writeCountKey) }
    }

    private var lastShownAt: Date? {
        get { defaults.object(forKey: lastShownAtKey) as? Date }
        set { defaults.set(newValue, forKey: lastShownAtKey) }
    }

    private var isEligible: Bool {
        guard writeCount >= minWriteCount else { return false }
        if let lastShownAt, Date().timeIntervalSince(lastShownAt) < cooldown { return false }
        return true
    }

    /// 글자를 새로 저장했을 때 호출한다.
    func recordWrite() {
        writeCount += 1
    }

    /// 노출 후보가 될 시점(글자 쓰기 화면 진입 등)에 미리 로드해 둔다.
    func preload() {
        guard ad == nil, !isLoading else { return }
        guard let adUnitID = Bundle.main.object(forInfoDictionaryKey: "AdMobInterstitialID") as? String else { return }
        isLoading = true
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, _ in
            guard let self else { return }
            isLoading = false
            self.ad = ad
            ad?.fullScreenContentDelegate = self
        }
    }

    /// 조건을 만족하면 노출하고 true를, 아니면 노출하지 않고 false를 반환한다.
    /// 노출 시 `onDismiss`는 광고가 닫히거나(또는 표시 실패 시) 호출된다.
    @discardableResult
    func presentIfEligible(from viewController: UIViewController, onDismiss: @escaping () -> Void) -> Bool {
        guard isEligible, let ad else { return false }
        dismissHandler = onDismiss
        self.ad = nil
        markShown()
        ad.present(from: viewController)
        return true
    }

    private func markShown() {
        writeCount = 0
        lastShownAt = Date()
        preload()
    }
}

// MARK: - FullScreenContentDelegate

extension InterstitialAdGate: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        dismissHandler?()
        dismissHandler = nil
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        dismissHandler?()
        dismissHandler = nil
    }
}
