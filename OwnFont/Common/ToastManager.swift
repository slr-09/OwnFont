//
//  ToastManager.swift
//  OwnFont
//
//  Created by 가은 on 4/16/26.
//

import UIKit
import SnapKit

enum ToastStyle {
    case success
    case error
    case info

    var backgroundColor: UIColor {
        switch self {
        case .success: return .green
        case .error:   return .primary
        case .info:    return .indigo
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

final class ToastManager {

    private static let toastTag = Int(bitPattern: ObjectIdentifier(ToastManager.self))

    static func show(
        _ message: String,
        style: ToastStyle = .info,
        duration: TimeInterval = 2.0
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { show(message, style: style, duration: duration) }
            return
        }

        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .compactMap({ $0.keyWindow })
            .first
        else { return }

        // 기존 토스트가 있으면 제거
        window.subviews
            .filter { $0.tag == toastTag }
            .forEach { $0.removeFromSuperview() }

        let toast = makeToastView(message: message, style: style)
        toast.tag = toastTag
        toast.alpha = 0

        window.addSubview(toast)

        toast.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).offset(-24)
            $0.leading.greaterThanOrEqualToSuperview().offset(24)
            $0.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: duration) {
                toast.alpha = 0
            } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Private

    private static func makeToastView(message: String, style: ToastStyle) -> UIView {
        let container = UIView()
        container.backgroundColor = style.backgroundColor
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 8

        let icon = UIImageView(image: UIImage(systemName: style.icon))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = message
        label.font = .body
        label.textColor = .white
        label.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        container.addSubview(stack)

        icon.snp.makeConstraints {
            $0.width.height.equalTo(18)
        }

        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        return container
    }
}
