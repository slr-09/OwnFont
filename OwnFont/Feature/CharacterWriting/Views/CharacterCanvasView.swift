//
//  CharacterCanvasView.swift
//  OwnFont
//

import UIKit
import SnapKit

final class CharacterCanvasView: UIView {

    private let guideCharLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 160, weight: .heavy)
        label.textColor = .primarySubtle
        label.textAlignment = .center
        label.alpha = 0.5
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .surface
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.surfaceSecondary.cgColor
        clipsToBounds = true

        addSubview(guideCharLabel)
        guideCharLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setGuideChar(_ char: String) {
        guideCharLabel.text = char
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let w = rect.width
        let h = rect.height

        // 3x3 격자선
        ctx.setStrokeColor(UIColor.surfaceSecondary.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 0, y: h / 3));      ctx.addLine(to: CGPoint(x: w, y: h / 3))
        ctx.move(to: CGPoint(x: 0, y: h * 2 / 3));  ctx.addLine(to: CGPoint(x: w, y: h * 2 / 3))
        ctx.move(to: CGPoint(x: w / 3, y: 0));       ctx.addLine(to: CGPoint(x: w / 3, y: h))
        ctx.move(to: CGPoint(x: w * 2 / 3, y: 0));   ctx.addLine(to: CGPoint(x: w * 2 / 3, y: h))
        ctx.strokePath()

    }
}
