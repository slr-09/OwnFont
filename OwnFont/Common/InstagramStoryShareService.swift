//
//  InstagramStoryShareService.swift
//  OwnFont
//

import UIKit

enum InstagramStoryShareService {

    /// 인스타그램 스토리 공유 URL scheme
    /// 참고: https://developers.facebook.com/docs/instagram-platform/sharing-to-stories/ios/
    private static let scheme = URL(string: "instagram-stories://share?source_application=ownfont")

    /// 인스타그램 미설치 시 이동할 앱스토어 URL (Instagram App Store ID: 389801252)
    private static let appStoreURL = URL(string: "https://apps.apple.com/app/instagram/id389801252")

    /// 편집된 이미지 PNG 데이터를 인스타그램 스토리로 공유한다.
    /// - Parameters:
    ///   - pngData: 배경 스티커로 사용할 PNG 데이터
    ///   - topColor: 상단 그라데이션 색 (Instagram이 사용)
    ///   - bottomColor: 하단 그라데이션 색
    /// - Returns: 공유 시도 성공 여부. 인스타그램 미설치 시 앱스토어로 이동하고 false.
    @discardableResult
    static func share(
        pngData: Data,
        topColor: UIColor = UIColor(hex: "FAFAFA"),
        bottomColor: UIColor = UIColor(hex: "FFFFFF")
    ) -> Bool {
        guard let scheme, UIApplication.shared.canOpenURL(scheme) else {
            // 인스타그램 미설치 — 앱스토어 설치 페이지로 이동
            if let appStoreURL {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
            return false
        }

        // stickerImage 로 넘기면 인스타가 카드를 스티커로 띄우고 그 뒤를
        // backgroundTop/BottomColor 그라데이션으로 채워준다.
        // backgroundImage 를 쓰면 PNG 의 투명한 둥근 모서리가 검정으로 합성되어 보임.
        let items: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": pngData,
            "com.instagram.sharedSticker.backgroundTopColor": topColor.hexString,
            "com.instagram.sharedSticker.backgroundBottomColor": bottomColor.hexString
        ]

        // 5분 만료 — 인스타가 그 안에 pasteboard에서 읽어감
        let expiration = Date().addingTimeInterval(60 * 5)
        UIPasteboard.general.setItems(
            [items],
            options: [.expirationDate: expiration]
        )

        UIApplication.shared.open(scheme, options: [:], completionHandler: nil)
        return true
    }
}

private extension UIColor {
    /// Instagram이 요구하는 "#RRGGBB" 형태
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
