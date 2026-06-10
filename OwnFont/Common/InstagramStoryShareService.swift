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

        // 사진/메모지 우측 하단에 앱 브랜딩(로고 + 앱명)을 합성한 뒤 stickerImage 로 넘긴다.
        // 브랜딩을 스티커에 직접 그려두면, 사용자가 인스타에서 스티커를 옮겨도
        // 브랜딩이 사진을 따라다닌다. 배경은 기존처럼 그라데이션으로 채운다.
        let stickerData = brandedSticker(from: pngData) ?? pngData
        let items: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": stickerData,
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

    /// 원본 사진/메모지 PNG 아래에 여백을 덧대고, 그 우측 하단(= 사진 바깥)에
    /// 앱 로고 + 앱명을 합성한 스티커를 만든다.
    private static func brandedSticker(from pngData: Data) -> Data? {
        guard let base = UIImage(data: pngData) else { return nil }

        let baseSize = base.size

        // 메모지/사진이 스토리에서 비슷한 너비로 표시되므로, 카드 너비 기준으로
        // 크기를 잡아 두 경우의 브랜딩이 일관된 크기로 보이게 한다.
        let logoSide = baseSize.width * 0.07   // 아이콘 크기 (작게)
        let logoCorner = logoSide * 0.22       // 앱 아이콘 느낌의 둥근 모서리
        let gap = logoSide * 0.34              // 로고-텍스트 간격
        let rightMargin = baseSize.width * 0.02 // 사진 우측 끝에서의 간격
        let topGap = logoSide * 0.55           // 사진 아래와 브랜딩 사이 간격
        let bottomGap = logoSide * 0.2         // 브랜딩 아래 여백

        let appName = bundleDisplayName
        let nameFont = UIFont.systemFont(ofSize: logoSide * 0.64, weight: .semibold)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: UIColor(white: 0.25, alpha: 0.9) // 밝은 배경 위에서 읽히도록
        ]
        let nameSize = (appName as NSString).size(withAttributes: nameAttributes)
        let logo = UIImage(named: "ShareLogo")

        let contentWidth = (logo != nil ? logoSide + gap : 0) + nameSize.width
        let contentHeight = max(logoSide, nameSize.height)

        // 사진 아래로 브랜딩 영역만큼 캔버스를 늘린다.
        let strip = topGap + contentHeight + bottomGap
        let size = CGSize(width: baseSize.width, height: baseSize.height + strip)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = base.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { ctx in
            let cgContext = ctx.cgContext
            base.draw(in: CGRect(origin: .zero, size: baseSize))

            // 사진 우측에 정렬, 늘린 영역 안에 세로 중앙
            var cursorX = baseSize.width - rightMargin - contentWidth
            let centerY = baseSize.height + topGap + contentHeight / 2

            if let logo {
                let logoRect = CGRect(
                    x: cursorX,
                    y: centerY - logoSide / 2,
                    width: logoSide,
                    height: logoSide
                )
                let clip = UIBezierPath(roundedRect: logoRect, cornerRadius: logoCorner)
                cgContext.saveGState()
                clip.addClip()
                logo.draw(in: logoRect)
                cgContext.restoreGState()
                cursorX += logoSide + gap
            }

            let nameRect = CGRect(
                x: cursorX,
                y: centerY - nameSize.height / 2,
                width: nameSize.width,
                height: nameSize.height
            )
            (appName as NSString).draw(in: nameRect, withAttributes: nameAttributes)
        }

        return image.pngData()
    }

    /// 앱 표시 이름 (Info.plist). 없으면 "OwnFont".
    private static var bundleDisplayName: String {
        let info = Bundle.main.infoDictionary
        return (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String)
            ?? "OwnFont"
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
