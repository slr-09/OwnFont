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
        let font = UIFont.systemFont(ofSize: size, weight: .regular)

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
