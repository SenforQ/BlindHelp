//
//  BHDiscoverPostPhotoViewController.swift
//  BlindHelp
//

import PhotosUI
import UIKit

final class BHDiscoverPostPhotoViewController: BHBaseViewController, UITextViewDelegate, PHPickerViewControllerDelegate {

    private enum ConsentLink {
        static let userTerms = URL(string: "bhpost://terms")!
        static let privacy = URL(string: "bhpost://privacy")!
    }

    private let sheetView = UIView()
    private let placeholderLabel = UILabel()
    private let contentTextView = UITextView()

    private let submitNavButton = UIButton(type: .custom)
    private let addPhotoButton = UIButton(type: .custom)

    private let consentCheckboxButton = UIButton(type: .custom)
    private let consentTextView = UITextView()

    private var pickedPhotos: [UIImage] = []
    private var pickerRemainingSlotsWhenPresented = 3

    private final class BHPostPhotoThumbnailCell: UIView {

        let previewView = UIImageView()
        let deleteOverlayBtn = UIButton(type: .custom)

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.cornerRadius = kScaleW(10)
            layer.masksToBounds = true

            previewView.contentMode = .scaleAspectFill
            previewView.clipsToBounds = true
            previewView.layer.cornerRadius = kScaleW(10)
            previewView.backgroundColor = .kHexColor(hexString: "#F2F2F2")

            deleteOverlayBtn.isHidden = true
            if let ximg = UIImage(systemName: "xmark.circle.fill")?.withTintColor(.white.withAlphaComponent(0.95), renderingMode: .alwaysOriginal) {
                deleteOverlayBtn.setImage(ximg, for: .normal)
            }
            deleteOverlayBtn.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            deleteOverlayBtn.layer.cornerRadius = kScaleW(12)
            deleteOverlayBtn.layer.masksToBounds = true

            addSubview(previewView)
            addSubview(deleteOverlayBtn)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewView.frame = bounds
            let d = kScaleW(24)
            deleteOverlayBtn.frame = CGRect(x: bounds.width - d - kScaleW(4), y: kScaleW(4), width: d, height: d)
        }

        func configure(image: UIImage?) {
            previewView.image = image
            let has = image != nil
            isHidden = !has
            deleteOverlayBtn.isHidden = !has
        }
    }

    private let thumbnailCells: [BHPostPhotoThumbnailCell] = (0..<3).map { _ in BHPostPhotoThumbnailCell(frame: .zero) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "发布动态"
        kdNavBar.navTitleLab.text = "发布动态"

        sheetView.backgroundColor = .white

        contentTextView.font = .bh_pingFang(size: 15, weight: .regular)
        contentTextView.textColor = .kHexColor(hexString: "#000000")
        contentTextView.backgroundColor = .clear
        contentTextView.textContainerInset = UIEdgeInsets(top: kScaleW(8), left: kScaleW(4), bottom: kScaleW(8), right: kScaleW(4))
        contentTextView.delegate = self

        placeholderLabel.text = "这一刻的想法..."
        placeholderLabel.font = contentTextView.font
        placeholderLabel.textColor = .kHexColor(hexString: "#C0C0C0")

        submitNavButton.setTitle("提交", for: .normal)
        submitNavButton.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
        submitNavButton.titleLabel?.font = .bh_pingFang(size: 14, weight: .medium)
        submitNavButton.backgroundColor = .kHexColor(hexString: "#A5F500")
        submitNavButton.contentEdgeInsets = UIEdgeInsets(
            top: kScaleW(6),
            left: kScaleW(16),
            bottom: kScaleW(6),
            right: kScaleW(16)
        )
        submitNavButton.layer.masksToBounds = true
        submitNavButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        kdNavBar.navigationView.addSubview(submitNavButton)
        kdNavBar.navigationView.bringSubviewToFront(submitNavButton)

        addPhotoButton.layer.cornerRadius = kScaleW(10)
        addPhotoButton.layer.masksToBounds = true
        addPhotoButton.backgroundColor = .kHexColor(hexString: "#F2F2F2")
        addPhotoButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        addPhotoButton.layer.borderColor = UIColor.kHexColor(hexString: "#E0E0E0").cgColor
        if let plus = UIImage(systemName: "plus")?.withTintColor(.kHexColor(hexString: "#999999"), renderingMode: .alwaysOriginal) {
            addPhotoButton.setImage(plus, for: .normal)
            addPhotoButton.adjustsImageWhenHighlighted = false
        }
        addPhotoButton.imageView?.contentMode = .scaleAspectFit
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        sheetView.addSubview(addPhotoButton)

        let linkColor = UIColor.kHexColor(hexString: "#2B6CF5")
        consentTextView.isEditable = false
        consentTextView.isScrollEnabled = false
        consentTextView.backgroundColor = .clear
        consentTextView.textContainerInset = .zero
        consentTextView.textContainer.lineFragmentPadding = 0
        consentTextView.textContainer.lineBreakMode = .byWordWrapping
        consentTextView.contentInset = .zero
        if #available(iOS 11.0, *) {
            consentTextView.contentInsetAdjustmentBehavior = .never
        }
        consentTextView.delaysContentTouches = false
        consentTextView.delegate = self
        consentTextView.linkTextAttributes = [
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        consentTextView.attributedText = Self.makeConsentAttributedString(linkColor: linkColor)

        consentCheckboxButton.adjustsImageWhenHighlighted = false
        if let circle = UIImage(systemName: "circle")?.withTintColor(.kHexColor(hexString: "#999999"), renderingMode: .alwaysOriginal),
           let checked = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.kHexColor(hexString: "#A5F500"), renderingMode: .alwaysOriginal) {
            consentCheckboxButton.setImage(circle, for: .normal)
            consentCheckboxButton.setImage(checked, for: .selected)
        }
        consentCheckboxButton.addTarget(self, action: #selector(consentCheckboxTapped), for: .touchUpInside)

        submitNavButton.setTitleColor(.kHexColor(hexString: "#999999"), for: .disabled)

        sheetView.addSubview(consentCheckboxButton)
        sheetView.addSubview(consentTextView)

        for (idx, cell) in thumbnailCells.enumerated() {
            cell.deleteOverlayBtn.tag = idx
            cell.deleteOverlayBtn.addTarget(self, action: #selector(thumbnailDeleteTapped(_:)), for: .touchUpInside)
            cell.isHidden = true
            sheetView.addSubview(cell)
        }

        sheetView.addSubview(placeholderLabel)
        sheetView.addSubview(contentTextView)
        reloadPhotoStripLayoutState()
        syncPlaceholderVisibility()
        syncSubmitButtonEnabledForConsent()
    }

    private static func makeConsentAttributedString(linkColor: UIColor) -> NSAttributedString {
        let bodyFont = UIFont.bh_pingFang(size: 12, weight: .regular)
        let gray = UIColor.kHexColor(hexString: "#666666")
        let base: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: gray]

        let full = NSMutableAttributedString(string: "已阅读并同意", attributes: base)

        let termsAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: linkColor,
            .link: ConsentLink.userTerms,
        ]
        full.append(NSAttributedString(string: "《用户协议》", attributes: termsAttrs))

        full.append(NSAttributedString(string: "和", attributes: base))

        let privacyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: linkColor,
            .link: ConsentLink.privacy,
        ]
        full.append(NSAttributedString(string: "《隐私政策》", attributes: privacyAttrs))

        return full
    }

    override func setupBodyView() {
        view.insertSubview(sheetView, belowSubview: kdNavBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let top = kNavBarFullHeight
        let W = view.bounds.width
        let sheetH = max(0, view.bounds.height - top)
        sheetView.frame = CGRect(x: 0, y: top, width: W, height: sheetH)

        let hInset = kScaleW(16)
        let textTop = kScaleW(12)
        let textH = kScaleW(160)
        contentTextView.frame = CGRect(x: hInset - kScaleW(4), y: textTop, width: W - hInset * 2 + kScaleW(8), height: textH)

        let insetL = contentTextView.textContainerInset.left + contentTextView.textContainer.lineFragmentPadding
        let insetT = contentTextView.textContainerInset.top
        let tw = contentTextView.frame.width
        placeholderLabel.frame = CGRect(
            x: contentTextView.frame.origin.x + insetL,
            y: contentTextView.frame.origin.y + insetT,
            width: max(0, tw - insetL - contentTextView.textContainerInset.right),
            height: ceil(placeholderLabel.font.lineHeight)
        )

        let rowY = contentTextView.frame.maxY + kScaleW(16)
        let gap = kScaleW(8)
        let contentW = W - hInset * 2
        let maxSlotsInRow = 4
        let side = (contentW - gap * CGFloat(maxSlotsInRow - 1)) / CGFloat(maxSlotsInRow)

        var x = hInset
        addPhotoButton.frame = CGRect(x: x, y: rowY, width: side, height: side)
        x = addPhotoButton.frame.maxX + gap

        for i in 0..<pickedPhotos.count {
            let cell = thumbnailCells[i]
            cell.isHidden = false
            cell.frame = CGRect(x: x, y: rowY, width: side, height: side)
            x = cell.frame.maxX + gap
        }

        let titleText = submitNavButton.title(for: .normal) ?? ""
        let titleFont = submitNavButton.titleLabel?.font ?? .bh_pingFang(size: 14, weight: .medium)
        let rawTitleWidth = ceil((titleText as NSString).size(withAttributes: [.font: titleFont]).width)
        let submitW = ceil(rawTitleWidth + submitNavButton.contentEdgeInsets.left + submitNavButton.contentEdgeInsets.right)
        let clampedSubmitW = max(submitW, kScaleW(52))
        let navContainer = kdNavBar.navigationView
        let navW = navContainer.bounds.width > 1 ? navContainer.bounds.width : kScreenWidth
        let submitH = kScaleW(32)
        let submitY = (kNavBarHeight - submitH) / 2
        submitNavButton.frame = CGRect(
            x: navW - clampedSubmitW - kScaleW(10),
            y: submitY,
            width: clampedSubmitW,
            height: submitH
        )
        submitNavButton.layer.cornerRadius = submitH / 2
        navContainer.bringSubviewToFront(submitNavButton)

        let consentGapTop = kScaleW(12)
        let consentRowTop = rowY + side + consentGapTop
        let chk = kScaleW(22)
        let tvX = hInset + chk + kScaleW(8)
        let tvW = max(0, W - tvX - hInset)

        consentTextView.frame = CGRect(x: tvX, y: consentRowTop, width: tvW, height: 1)
        let fitH = consentTextView.sizeThatFits(CGSize(width: tvW, height: CGFloat.greatestFiniteMagnitude)).height
        let consentFont = UIFont.bh_pingFang(size: 12, weight: .regular)
        let tvH = max(ceil(consentFont.lineHeight), ceil(fitH))

        let rowH = max(chk, tvH)
        let rowYAligned = consentRowTop
        consentTextView.frame = CGRect(x: tvX, y: rowYAligned + (rowH - tvH) / 2, width: tvW, height: tvH)
        consentCheckboxButton.frame = CGRect(x: hInset, y: rowYAligned + (rowH - chk) / 2, width: chk, height: chk)
    }

    @objc private func consentCheckboxTapped() {
        consentCheckboxButton.isSelected.toggle()
        syncSubmitButtonEnabledForConsent()
    }

    private func syncSubmitButtonEnabledForConsent() {
        let ok = consentCheckboxButton.isSelected
        submitNavButton.isEnabled = ok
        submitNavButton.alpha = ok ? 1 : 0.55
    }

    @objc private func addPhotoTapped() {
        guard pickedPhotos.count < 3 else { return }
        let remain = 3 - pickedPhotos.count
        presentPhotoPicker(maxSelection: remain)
    }

    @objc private func thumbnailDeleteTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx >= 0, idx < pickedPhotos.count else { return }
        pickedPhotos.remove(at: idx)
        reloadPhotoStripLayoutState()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func presentPhotoPicker(maxSelection: Int) {
        pickerRemainingSlotsWhenPresented = max(1, min(3, maxSelection))
        var cfg = PHPickerConfiguration()
        cfg.filter = .images
        cfg.selectionLimit = pickerRemainingSlotsWhenPresented
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        var loaded: [UIImage] = []
        let lock = NSLock()

        for result in results.prefix(pickerRemainingSlotsWhenPresented) {
            let provider = result.itemProvider
            guard provider.canLoadObject(ofClass: UIImage.self) else { continue }
            group.enter()
            provider.loadObject(ofClass: UIImage.self) { obj, _ in
                defer { group.leave() }
                guard let img = obj as? UIImage else { return }
                lock.lock()
                loaded.append(img)
                lock.unlock()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let room = 3 - self.pickedPhotos.count
            guard room > 0 else { return }
            self.pickedPhotos.append(contentsOf: Array(loaded.prefix(room)))
            self.reloadPhotoStripLayoutState()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    private func reloadPhotoStripLayoutState() {
        for i in 0..<thumbnailCells.count {
            if i < pickedPhotos.count {
                thumbnailCells[i].configure(image: pickedPhotos[i])
            } else {
                thumbnailCells[i].configure(image: nil)
            }
        }
        let full = pickedPhotos.count >= 3
        addPhotoButton.isEnabled = !full
        addPhotoButton.alpha = full ? 0.42 : 1
    }

    @objc private func submitTapped() {
        guard consentCheckboxButton.isSelected else {
            view.cd_showDefaultToast("请先阅读并勾选同意用户协议与隐私政策")
            return
        }

        let t = contentTextView.text ?? ""
        let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !pickedPhotos.isEmpty else {
            view.cd_showDefaultToast("请填写内容或添加图片")
            return
        }

        let snapsText = t
        let snaps = pickedPhotos

        contentTextView.isEditable = false
        submitNavButton.isEnabled = false
        view.isUserInteractionEnabled = false
        view.cd_showActivity()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self else { return }
            _ = BHMineWorldDynamicStore.shared.append(text: snapsText, images: snaps)
            self.view.cd_hidToast()
            self.contentTextView.isEditable = true
            self.syncSubmitButtonEnabledForConsent()
            self.view.isUserInteractionEnabled = true
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func syncPlaceholderVisibility() {
        let empty = (contentTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = !empty
    }

    func textViewDidChange(_ textView: UITextView) {
        guard textView === contentTextView else { return }
        syncPlaceholderVisibility()
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard textView === consentTextView else { return true }
        if url == ConsentLink.userTerms {
            navigationController?.pushViewController(BHMineUserTermsViewController(), animated: true)
            return false
        }
        if url == ConsentLink.privacy {
            navigationController?.pushViewController(BHMinePrivateViewController(), animated: true)
            return false
        }
        return false
    }
}
