//
//  TextEditorViewController.swift
//  OwnFont
//

import UIKit

final class TextEditorViewController: UIViewController {

    private var contentView: TextEditorView { view as! TextEditorView }

    // MARK: - Lifecycle

    override func loadView() {
        view = TextEditorView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindCallbacks()
        contentView.textView.delegate = self
        
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
        contentView.onBackTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        contentView.onFontSizeChange = { [weak self] size in
            self?.updateFontSize(size)
        }
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

        // 폰트 변경 후 GlyphLayoutManager에 전체 범위 리렌더링 요청
        // setNeedsDisplay()만으로는 커스텀 NSLayoutManager가 재실행되지 않을 수 있음
        let lm = tv.layoutManager
        let fullRange = NSRange(location: 0, length: tv.textStorage.length)
        lm.invalidateDisplay(forGlyphRange: fullRange)
        tv.setNeedsDisplay()
    }
}

// MARK: - UITextViewDelegate

extension TextEditorViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        contentView.setPlaceholderVisible(textView.text.isEmpty)
    }

    // UITextViewDelegate ⊃ UIScrollViewDelegate
    // contentOffset.x를 항상 0으로 고정해 좌우 스크롤 차단
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
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
