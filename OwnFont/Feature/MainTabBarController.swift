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
            title: "꾸미기",
            image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"),
            selectedImage: UIImage(systemName: "rectangle.and.pencil.and.ellipsis.rtl")
        )

        let characterSetVC = CharacterSetViewController()
        let charNav = UINavigationController(rootViewController: characterSetVC)
        charNav.tabBarItem = UITabBarItem(
            title: "글자 세트",
            image: UIImage(systemName: "character.ko"),
            selectedImage: UIImage(systemName: "character.ko")
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
