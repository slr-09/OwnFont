//
//  AppDelegate.swift
//  OwnFont
//
//  Created by 가은 on 4/9/26.
//

import UIKit
import FirebaseCore
import FirebaseAnalytics
import GoogleMobileAds
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // NSPersistentContainer 로드 전에 Transformer를 반드시 등록해야 합니다.
        CGPathTransformer.register()
        
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        requestTrackingAuthorization()

        return true
    }

    private func requestTrackingAuthorization() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                MobileAds.shared.start()
            }
        } else {
            MobileAds.shared.start()
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

