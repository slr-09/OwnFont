//
//  DateFormatManager.swift
//  OwnFont
//

import Foundation

final class DateFormatManager {

    static let shared = DateFormatManager()

    private let dateFormatter = DateFormatter()

    private init() {
        let isKorean = Locale.preferredLanguages.first?.hasPrefix("ko") ?? false
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = isKorean ? "yyyy년 M월 d일" : "MMM d, yyyy"
    }

    // MARK: - Public

    func formattedDate(from date: Date = Date()) -> String {
        dateFormatter.string(from: date)
    }
}
