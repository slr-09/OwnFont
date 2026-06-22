//
//  UIViewController+Alert.swift
//  OwnFont
//

import UIKit

extension UIViewController {
    func presentAlert(_ alert: UIAlertController, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  isViewLoaded,
                  view.window != nil,
                  presentedViewController == nil else { return }

            present(alert, animated: animated)
        }
    }

    func presentAlert(
        title: String,
        message: String,
        confirmTitle: String = L.buttonConfirm,
        animated: Bool = true
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default))
        presentAlert(alert, animated: animated)
    }
}
