//
//  TextEditorViewController.swift
//  OwnFont
//

import Combine
import UIKit

final class TextEditorViewController: UIViewController {

    private var contentView: TextEditorView { view as! TextEditorView }
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func loadView() {
        view = TextEditorView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindCallbacks()
        bindPlaceholder()
        bindGlyphKerning()

        // 1. 드래그로 키보드 내리기
        contentView.textView.keyboardDismissMode = .onDrag

        // 2. 텍스트 영역 외(상단 탑바, 하단 빈공간 등) 탭으로 키보드 내리기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Handlers

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentView.textView.becomeFirstResponder()
    }

    // MARK: - Bind

    private func bindCallbacks() {
        contentView.actionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .back:
                    navigationController?.popViewController(animated: true)
                case .fontSizeChanged(let size):
                    updateFontSize(size)
                }
            }
            .store(in: &cancellables)
    }

    private func bindPlaceholder() {
        NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: contentView.textView)
            .compactMap { ($0.object as? UITextView)?.text.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.contentView.setPlaceholderVisible(isEmpty)
            }
            .store(in: &cancellables)
    }

    private func bindGlyphKerning() {
        NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: contentView.textView)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyGlyphKerning()
            }
            .store(in: &cancellables)
    }

    // 커스텀 글리프 문자의 advance를 실제 렌더 폭에 맞추기 위해 .kern 보정
    // 렌더 폭 = emSize × (font.ascender / usableHeight) (GlyphLayoutManager의 scaleX와 동일)
    private func applyGlyphKerning() {
        let storage = contentView.textView.textStorage
        let text = storage.string as NSString
        let length = text.length
        guard length > 0 else { return }

        storage.beginEditing()
        for i in 0..<length {
            let charRange = NSRange(location: i, length: 1)
            let char = text.substring(with: charRange)
            let font = storage.attribute(.font, at: i, effectiveRange: nil) as? UIFont ?? .bodyHeader

            guard let glyphData = GlyphStore.shared.glyph(for: char) else {
                storage.removeAttribute(.kern, range: charRange)
                continue
            }

            // 실제 ink 폭(bbox.width) × scaleY 를 렌더 폭으로 사용 + 우측 side bearing 으로
            // 글자 사이 간격 확보 (pointSize의 12%)
            let scaleY = font.ascender / GlyphNormalizer.usableHeight
            let bbox = glyphData.normalizedPath.boundingBox
            let renderedWidth = bbox.width * scaleY
            let sideBearing = font.pointSize * 0.12
            let advance = (char as NSString).size(withAttributes: [.font: font]).width
            let kern = renderedWidth + sideBearing - advance
            storage.addAttribute(.kern, value: kern, range: charRange)
        }
        storage.endEditing()
    }

    // MARK: - Font Size

    private func updateFontSize(_ size: CGFloat) {
        let tv = contentView.textView
        let font = UIFont.custom(size: size)

        // 전체 텍스트에 새 폰트 적용
        if tv.text.isEmpty {
            tv.font = font
        } else {
            let range = NSRange(location: 0, length: tv.textStorage.length)
            tv.textStorage.addAttribute(.font, value: font, range: range)
        }

        applyGlyphKerning()

        // 폰트 변경 후 GlyphLayoutManager에 전체 범위 리렌더링 요청
        // setNeedsDisplay()만으로는 커스텀 NSLayoutManager가 재실행되지 않을 수 있음
        let lm = tv.layoutManager
        let fullRange = NSRange(location: 0, length: tv.textStorage.length)
        lm.invalidateDisplay(forGlyphRange: fullRange)
        tv.setNeedsDisplay()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextEditorViewController: UIGestureRecognizerDelegate {
    
    // 텍스트를 터치해서 커서를 이동할 때는 키보드가 내려가지 않도록 예외 처리
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return true }
        // 네비게이션 바 등 텍스트뷰 바깥 영역은 늘 탭을 허용 (키보드 내려감)
        if !view.isDescendant(of: contentView.textView) { return true }
        
        let textView = contentView.textView
        let point = touch.location(in: textView)
        
        // 작성된 텍스트가 실제로 차지하는 높이를 계산 (위아래 여백 포함)
        let layoutManager = textView.layoutManager
        let usedRect = layoutManager.usedRect(for: textView.textContainer)
        let maxTextY = usedRect.maxY + textView.textContainerInset.top + textView.textContainerInset.bottom
        
        // 텍스트 맨 아랫줄 아래의 진짜 빈 공간(배경)을 누른 거라면 키보드 내려감 허용
        if point.y > maxTextY {
            return true
        }
        
        // 글씨 위를 누른 거라면 커서 이동을 위해 무시
        return false
    }
}
