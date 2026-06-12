//
//  MainTabBarController.swift
//  OwnFont
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let cardHomeVC = CardHomeViewController()
        let cardNav = UINavigationController(rootViewController: cardHomeVC)
        cardNav.tabBarItem = UITabBarItem(
            title: L.tabBarDecorate,
            image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"),
            selectedImage: UIImage(systemName: "rectangle.and.pencil.and.ellipsis.rtl")
        )

        let characterSetVC = CharacterSetViewController()
        let charNav = UINavigationController(rootViewController: characterSetVC)
        charNav.tabBarItem = UITabBarItem(
            title: L.tabBarCharacterSet,
            image: UIImage(systemName: L.tabBarCharacterIcon),
            selectedImage: UIImage(systemName: L.tabBarCharacterIcon)
        )

        viewControllers = [cardNav, charNav]
    }
 
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .surface

        let normalAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.textHint]
        let selectedAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.primary]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.stackedLayoutAppearance.normal.iconColor = .textHint
        appearance.stackedLayoutAppearance.selected.iconColor = .primary

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
