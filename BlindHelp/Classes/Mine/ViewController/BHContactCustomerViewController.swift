 //
//  BHContactCustomerViewController.swift
//  BlindHelp
//

import UIKit

final class BHContactCustomerViewController: BHBaseViewController, UITextViewDelegate, UITextFieldDelegate {

    private let scrollView = UIScrollView()
    private let bodyContentView = UIView()

    private let titleTipLab = UILabel()
    private let titleField = UITextField()

    private let contentTipLab = UILabel()
    private let contentContainer = UIView()
    private let contentTextView = UITextView()
    private let contentPlaceholderLab = UILabel()

    private let submitBtn = UIButton(type: .custom)

    private var isWaitingSubmitResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "联系客服"
        kdNavBar.navTitleLab.text = "联系客服"

        titleTipLab.text = "反馈标题"
        titleTipLab.font = .bh_pingFang(size: 14, weight: .medium)
        titleTipLab.textColor = .kHexColor(hexString: "#111111")

        titleField.placeholder = "请简要概括您的问题（必填）"
        titleField.font = .bh_pingFang(size: 14, weight: .regular)
        titleField.textColor = .kHexColor(hexString: "#000000")
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: kScaleW(12), height: kScaleW(44)))
        titleField.leftViewMode = .always
        titleField.backgroundColor = .kHexColor(hexString: "#F0F0F0")
        titleField.layer.cornerRadius = kScaleW(10)
        titleField.layer.masksToBounds = true
        titleField.delegate = self
        titleField.returnKeyType = .next
        titleField.autocapitalizationType = .none

        contentTipLab.text = "反馈内容"
        contentTipLab.font = .bh_pingFang(size: 14, weight: .medium)
        contentTipLab.textColor = .kHexColor(hexString: "#111111")

        contentContainer.backgroundColor = .kHexColor(hexString: "#F0F0F0")
        contentContainer.layer.cornerRadius = kScaleW(10)
        contentContainer.layer.masksToBounds = true

        contentTextView.backgroundColor = .clear
        contentTextView.font = .bh_pingFang(size: 14, weight: .regular)
        contentTextView.textColor = .kHexColor(hexString: "#000000")
        contentTextView.textContainerInset = UIEdgeInsets(
            top: kScaleW(10),
            left: kScaleW(8),
            bottom: kScaleW(10),
            right: kScaleW(8)
        )
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.delegate = self

        contentPlaceholderLab.text = "请详细描述您遇到的问题或建议（必填）"
        contentPlaceholderLab.font = .bh_pingFang(size: 14, weight: .regular)
        contentPlaceholderLab.textColor = .kHexColor(hexString: "#777777")
        contentPlaceholderLab.numberOfLines = 0

        submitBtn.layer.cornerRadius = kScaleW(25)
        submitBtn.layer.masksToBounds = true
        submitBtn.backgroundColor = .kHexColor(hexString: "#A5F500")
        submitBtn.setTitle("提交反馈", for: .normal)
        submitBtn.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
        submitBtn.titleLabel?.font = .bh_pingFang(size: 16, weight: .medium)
        submitBtn.addTarget(self, action: #selector(submitBtnTapped), for: .touchUpInside)

        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
    }

    override func setupBodyView() {
        view.addSubview(scrollView)
        scrollView.addSubview(bodyContentView)
        bodyContentView.addSubview(titleTipLab)
        bodyContentView.addSubview(titleField)
        bodyContentView.addSubview(contentTipLab)
        bodyContentView.addSubview(contentContainer)
        contentContainer.addSubview(contentPlaceholderLab)
        contentContainer.addSubview(contentTextView)
        bodyContentView.addSubview(submitBtn)
        refreshContentPlaceholderVisibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        let scrollH = view.bounds.height - kNavBarFullHeight
        scrollView.frame = CGRect(x: 0, y: kNavBarFullHeight, width: w, height: scrollH)

        let pad = kScaleW(14)
        var y: CGFloat = kScaleW(8)

        titleTipLab.frame = CGRect(x: pad, y: y, width: w - pad * 2, height: kScaleW(22))
        y = titleTipLab.bottom + kScaleW(6)

        titleField.frame = CGRect(x: pad, y: y, width: w - pad * 2, height: kScaleW(46))
        y = titleField.bottom + kScaleW(18)

        contentTipLab.frame = CGRect(x: pad, y: y, width: w - pad * 2, height: kScaleW(22))
        y = contentTipLab.bottom + kScaleW(6)

        let marginBelowFeedbackBlock = kScaleW(24) + kScaleW(50) + kScaleW(28) + kBottomSafeHeight
        let remainingForText = scrollH - y - marginBelowFeedbackBlock
        let contentH = max(kScaleW(160), remainingForText)

        contentContainer.frame = CGRect(x: pad, y: y, width: w - pad * 2, height: contentH)
        contentPlaceholderLab.frame = CGRect(
            x: kScaleW(10),
            y: kScaleW(12),
            width: contentContainer.bounds.width - kScaleW(20),
            height: kScaleW(60)
        )
        contentTextView.frame = contentContainer.bounds
        y = contentContainer.bottom + kScaleW(24)

        submitBtn.frame = CGRect(x: pad, y: y, width: w - pad * 2, height: kScaleW(50))
        submitBtn.layer.cornerRadius = submitBtn.bounds.height / 2

        y = submitBtn.bottom + kScaleW(28)
        bodyContentView.frame = CGRect(x: 0, y: 0, width: w, height: y)
        scrollView.contentSize = CGSize(width: w, height: y)
    }

    func textViewDidChange(_ textView: UITextView) {
        refreshContentPlaceholderVisibility()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === titleField {
            contentTextView.becomeFirstResponder()
        }
        return true
    }

    private func refreshContentPlaceholderVisibility() {
        let empty = contentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        contentPlaceholderLab.isHidden = !empty
    }

    @objc private func submitBtnTapped() {
        view.endEditing(true)
        guard !isWaitingSubmitResult else { return }

        let ttl = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cnt = contentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !ttl.isEmpty, !cnt.isEmpty else {
            view.cd_showDefaultToast("请填写反馈标题和内容")
            return
        }

        submitBtn.isEnabled = false
        titleField.isEnabled = false
        contentTextView.isEditable = false
        isWaitingSubmitResult = true
        view.cd_showActivity()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            self.view.cd_hidToast()

            guard self.navigationController != nil else { return }

            self.view.cd_showDurationToast("提交成功", duration: 1)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }
                self.view.cd_hidToast()
                if let nav = self.navigationController {
                    nav.popViewController(animated: true)
                }
            }
        }
    }
}
