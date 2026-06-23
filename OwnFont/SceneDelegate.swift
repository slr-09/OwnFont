//
//  SceneDelegate.swift
//  OwnFont
//
//  Created by 가은 on 4/9/26.
//

import UIKit
import AppTrackingTransparency
import GoogleMobileAds

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var didRequestTrackingAuthorization = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainTabBarController()
        window?.overrideUserInterfaceStyle = .light
        window?.makeKeyAndVisible()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageChange),
            name: LanguageManager.languageDidChange,
            object: nil
        )
    }

    @objc private func handleLanguageChange() {
        guard let window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = MainTabBarController()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestTrackingAuthorizationIfNeeded()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}

    private func requestTrackingAuthorizationIfNeeded() {
        guard !didRequestTrackingAuthorization else { return }

        if #available(iOS 14, *) {
            guard UIApplication.shared.applicationState == .active else { return }

            let status = ATTrackingManager.trackingAuthorizationStatus
            print("ATT status before request: \(status.rawValue)")

            guard status == .notDetermined else {
                didRequestTrackingAuthorization = true
                MobileAds.shared.start()
                return
            }

            didRequestTrackingAuthorization = true
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    print("ATT status after request: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")
                    MobileAds.shared.start()
                }
            }
        } else {
            MobileAds.shared.start()
        }
    }
}
