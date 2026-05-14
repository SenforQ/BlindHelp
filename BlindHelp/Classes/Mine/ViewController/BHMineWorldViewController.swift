//
//  BHMineWorldViewController.swift
//  BlindHelp
//

import UIKit

private final class BHMineWorldDynamicImageThumbControl: UIControl {

    private let preview = UIImageView()
    private(set) var hasPhoto = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = kScaleW(10)
        layer.masksToBounds = true
        backgroundColor = .kHexColor(hexString: "#F2F2F2")
        preview.contentMode = .scaleAspectFill
        preview.clipsToBounds = true
        preview.isUserInteractionEnabled = false
        addSubview(preview)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        preview.frame = bounds
    }

    func apply(image: UIImage?) {
        preview.image = image
        hasPhoto = image != nil
        isHidden = !hasPhoto
    }
}

final class BHMineWorldDynamicTableViewCell: UITableViewCell {

    static let reuseIdentifier = "BHMineWorldDynamicTableViewCell"

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let pendingLabel = UILabel()
    private let bodyLabel = UILabel()
    private let thumbControls: [BHMineWorldDynamicImageThumbControl]

    private var onImageTapAtIndex: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        thumbControls = (0..<3).map { _ in BHMineWorldDynamicImageThumbControl(frame: .zero) }

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        for (idx, c) in thumbControls.enumerated() {
            c.tag = idx
            c.addTarget(self, action: #selector(thumbControlTapped(_:)), for: .touchUpInside)
        }

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true

        nameLabel.font = .bh_pingFang(size: 16, weight: .medium)
        nameLabel.textColor = .kHexColor(hexString: "#000000")

        timeLabel.font = .bh_pingFang(size: 12, weight: .regular)
        timeLabel.textColor = .kHexColor(hexString: "#999999")

        pendingLabel.text = "待审核"
        pendingLabel.font = .bh_pingFang(size: 12, weight: .medium)
        pendingLabel.textColor = .kHexColor(hexString: "#FF9500")
        pendingLabel.textAlignment = .right

        bodyLabel.font = .bh_pingFang(size: 15, weight: .regular)
        bodyLabel.textColor = .kHexColor(hexString: "#000000")
        bodyLabel.numberOfLines = 0

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(pendingLabel)
        contentView.addSubview(bodyLabel)

        for c in thumbControls {
            contentView.addSubview(c)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.bounds.width
        guard w > 1 else { return }
        layOutFrames(tableWidth: w)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(record: BHMineWorldDynamicRecord, tableWidth: CGFloat, onImageTap: ((Int) -> Void)? = nil) {
        onImageTapAtIndex = onImageTap

        let snap = BHUserProfileManager.shared.currentProfileSnapshot()
        nameLabel.text = snap.nickname
        avatarView.image = BHUserProfileManager.shared.loadAvatarForDisplay()

        bodyLabel.text = record.text

        pendingLabel.text = "待审核"
        pendingLabel.textColor = .kHexColor(hexString: "#FF9500")

        timeLabel.text = Self.relativeTime(from: record.createdAt)

        let names = Array(record.imageFileNames.prefix(3))
        for (i, c) in thumbControls.enumerated() {
            if i < names.count {
                let url = BHMineWorldDynamicStore.shared.imageFileURL(for: names[i])
                c.apply(image: UIImage(contentsOfFile: url.path))
            } else {
                c.apply(image: nil)
            }
        }

        layOutFrames(tableWidth: tableWidth)
    }

    @objc private func thumbControlTapped(_ sender: BHMineWorldDynamicImageThumbControl) {
        guard !sender.isHidden, sender.hasPhoto else { return }
        onImageTapAtIndex?(sender.tag)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onImageTapAtIndex = nil
        bodyLabel.text = nil
        for c in thumbControls {
            c.apply(image: nil)
        }
    }

    private func layOutFrames(tableWidth: CGFloat) {
        let W = tableWidth
        let hInset = kScaleW(16)
        let topPad = kScaleW(16)
        let avatarS = kScaleW(40)
        let avatarX = hInset
        let avatarY = topPad

        avatarView.frame = CGRect(x: avatarX, y: avatarY, width: avatarS, height: avatarS)
        avatarView.layer.cornerRadius = avatarS / 2

        pendingLabel.sizeToFit()
        let pendingW = pendingLabel.bounds.width
        pendingLabel.frame = CGRect(
            x: W - hInset - pendingW,
            y: avatarY + kScaleW(1),
            width: pendingW,
            height: ceil(pendingLabel.font.lineHeight)
        )

        let nameX = avatarView.frame.maxX + kScaleW(10)
        let nameAvailW = max(0, W - hInset - nameX - pendingW - kScaleW(10))
        nameLabel.frame = CGRect(x: nameX, y: avatarY, width: nameAvailW, height: kScaleW(22))

        timeLabel.frame = CGRect(x: nameX, y: nameLabel.frame.maxY + kScaleW(4), width: nameAvailW, height: kScaleW(17))

        let headBottom = max(avatarView.frame.maxY, timeLabel.frame.maxY)
        var y = headBottom + kScaleW(12)

        let textW = W - hInset * 2
        let rawBody = bodyLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if rawBody.isEmpty {
            bodyLabel.frame = CGRect(x: hInset, y: y, width: textW, height: 0)
        } else {
            let bounded = (bodyLabel.text ?? "") as NSString
            let h = bounded.boundingRect(
                with: CGSize(width: textW, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: bodyLabel.font!],
                context: nil
            ).height
            let textH = ceil(h)
            bodyLabel.frame = CGRect(x: hInset, y: y, width: textW, height: textH)
            y += textH
        }

        let visibleCount = thumbControls.filter { !$0.isHidden }.count
        if visibleCount > 0 {
            y += kScaleW(12)
            let gap = kScaleW(8)
            let side = (textW - gap * 2) / 3
            var col = 0
            for c in thumbControls where !c.isHidden {
                c.frame = CGRect(x: hInset + CGFloat(col) * (side + gap), y: y, width: side, height: side)
                c.layer.cornerRadius = kScaleW(10)
                col += 1
            }
        }
    }

    static func rowHeight(for record: BHMineWorldDynamicRecord, tableWidth: CGFloat) -> CGFloat {
        let hInset = kScaleW(16)
        let topPad = kScaleW(16)
        let avatarH = kScaleW(40)
        let timeH = kScaleW(22) + kScaleW(4) + kScaleW(17)
        let headBottom = topPad + max(avatarH, timeH)
        let textW = tableWidth - hInset * 2
        let font = UIFont.bh_pingFang(size: 15, weight: .regular)
        let textH: CGFloat
        if record.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textH = 0
        } else {
            textH = ceil((record.text as NSString).boundingRect(
                with: CGSize(width: textW, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height)
        }
        var y = headBottom + kScaleW(12) + textH
        let imgCount = min(3, record.imageFileNames.count)
        if imgCount > 0 {
            y += kScaleW(12)
            let gap = kScaleW(8)
            let side = (textW - gap * 2) / 3
            y += side
        }
        y += kScaleW(20)
        return y
    }

    private static func relativeTime(from createdAt: TimeInterval) -> String {
        let d = Date(timeIntervalSince1970: createdAt)
        let sec = Date().timeIntervalSince(d)
        if sec < 60 { return "刚刚" }
        if sec < 3600 { return "\(max(1, Int(sec / 60)))分钟前" }
        if sec < 86400 { return "\(max(1, Int(sec / 3600)))小时前" }
        return "\(max(1, Int(sec / 86400)))天前"
    }
}

final class BHMineWorldViewController: BHBaseViewController, UITableViewDataSource, UITableViewDelegate {

    private var dynamicsRecords: [BHMineWorldDynamicRecord] = []

    private let emptyContainer = UIView()
    private let emptyImageView = UIImageView()
    private let emptyTipsLabel = UILabel()
    private let goPublishButton = UIButton(type: .custom)

    private let publishNavButton = UIButton(type: .custom)

    private let dynamicsListSurface: UIView = {
        let v = UIView()
        v.isHidden = true
        v.backgroundColor = .white
        return v
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.separatorStyle = .none
        t.backgroundColor = .white
        t.showsVerticalScrollIndicator = true
        t.alwaysBounceVertical = false
        t.delaysContentTouches = false
        if #available(iOS 15.0, *) {
            t.sectionHeaderTopPadding = 0
        }
        return t
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的世界"
        kdNavBar.navTitleLab.text = "我的世界"

        emptyImageView.image = UIImage(named: "mine_world_nodata")
        emptyImageView.contentMode = .scaleAspectFit

        emptyTipsLabel.text = "暂无动态"
        emptyTipsLabel.font = .bh_pingFang(size: 15, weight: .regular)
        emptyTipsLabel.textColor = .kHexColor(hexString: "#666666")
        emptyTipsLabel.textAlignment = .center

        goPublishButton.setTitle("前往发布", for: .normal)
        goPublishButton.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
        goPublishButton.titleLabel?.font = .bh_pingFang(size: 16, weight: .medium)
        goPublishButton.backgroundColor = .kHexColor(hexString: "#A5F500")
        goPublishButton.layer.masksToBounds = true
        goPublishButton.addTarget(self, action: #selector(goPublishButtonTapped), for: .touchUpInside)

        publishNavButton.setTitle("发布", for: .normal)
        publishNavButton.setTitleColor(.kHexColor(hexString: "#000000"), for: .normal)
        publishNavButton.titleLabel?.font = .bh_pingFang(size: 14, weight: .medium)
        publishNavButton.backgroundColor = .kHexColor(hexString: "#A5F500")
        publishNavButton.contentEdgeInsets = UIEdgeInsets(
            top: kScaleW(6),
            left: kScaleW(16),
            bottom: kScaleW(6),
            right: kScaleW(16)
        )
        publishNavButton.layer.masksToBounds = true
        publishNavButton.isHidden = true
        publishNavButton.addTarget(self, action: #selector(publishNavCapsuleTapped), for: .touchUpInside)
        kdNavBar.navigationView.addSubview(publishNavButton)
        kdNavBar.navigationView.bringSubviewToFront(publishNavButton)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BHMineWorldDynamicTableViewCell.self, forCellReuseIdentifier: BHMineWorldDynamicTableViewCell.reuseIdentifier)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onMineWorldDynamicsDidUpdate),
            name: .bhMineWorldDynamicsDidUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onUserProfileDidUpdate),
            name: .bhUserProfileDidUpdate,
            object: nil
        )

        reloadDynamicsFromStore()
    }

    @objc private func onMineWorldDynamicsDidUpdate() {
        reloadDynamicsFromStore()
    }

    @objc private func onUserProfileDidUpdate() {
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDynamicsFromStore()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || isBeingDismissed else { return }
        NotificationCenter.default.removeObserver(self)
    }

    private func reloadDynamicsFromStore() {
        dynamicsRecords = BHMineWorldDynamicStore.shared.allRecordsNewestFirst()
        tableView.reloadData()
        refreshEmptyAppearance()
    }

    override func setupBodyView() {
        emptyContainer.backgroundColor = .white
        view.insertSubview(emptyContainer, belowSubview: kdNavBar)
        emptyContainer.addSubview(emptyImageView)
        emptyContainer.addSubview(emptyTipsLabel)
        emptyContainer.addSubview(goPublishButton)
        view.insertSubview(dynamicsListSurface, belowSubview: kdNavBar)
        dynamicsListSurface.addSubview(tableView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let top = kNavBarFullHeight
        let restH = max(0, view.bounds.height - top)
        let W = view.bounds.width

        emptyContainer.frame = CGRect(x: 0, y: top, width: W, height: restH)
        dynamicsListSurface.frame = emptyContainer.frame
        tableView.frame = dynamicsListSurface.bounds

        let imgW = kScaleW(258)
        let imgH = kScaleW(180)
        let spacing1 = kScaleW(22)
        let spacing2 = kScaleW(24)
        let horizontalInset = kScaleW(48)
        let btnH = kScaleW(48)
        let btnWDesired = kScaleW(200)
        let btnW = min(btnWDesired, W - horizontalInset)

        let tipH = ceil(emptyTipsLabel.font.lineHeight)
        let contentH = imgH + spacing1 + tipH + spacing2 + btnH
        let yBase = max(kScaleW(32), (restH - contentH) / 2)

        emptyImageView.frame = CGRect(x: (W - imgW) / 2, y: yBase, width: imgW, height: imgH)
        emptyTipsLabel.frame = CGRect(
            x: horizontalInset / 2,
            y: emptyImageView.frame.maxY + spacing1,
            width: W - horizontalInset,
            height: tipH
        )

        let btnY = emptyTipsLabel.frame.maxY + spacing2
        goPublishButton.frame = CGRect(x: (W - btnW) / 2, y: btnY, width: btnW, height: btnH)
        goPublishButton.layer.cornerRadius = goPublishButton.bounds.height / 2

        let navContainer = kdNavBar.navigationView
        let navW = navContainer.bounds.width > 1 ? navContainer.bounds.width : kScreenWidth
        let publishTitleText = publishNavButton.title(for: .normal) ?? ""
        let publishTitleFont = publishNavButton.titleLabel?.font ?? .bh_pingFang(size: 14, weight: .medium)
        let publishRawTitleW = ceil((publishTitleText as NSString).size(withAttributes: [.font: publishTitleFont]).width)
        let publishW = ceil(publishRawTitleW + publishNavButton.contentEdgeInsets.left + publishNavButton.contentEdgeInsets.right)
        let publishClampedW = max(publishW, kScaleW(52))
        let publishH = kScaleW(32)
        let publishY = (kNavBarHeight - publishH) / 2
        publishNavButton.frame = CGRect(
            x: navW - publishClampedW - kScaleW(10),
            y: publishY,
            width: publishClampedW,
            height: publishH
        )
        publishNavButton.layer.cornerRadius = publishH / 2
        navContainer.bringSubviewToFront(publishNavButton)
    }

    private func refreshEmptyAppearance() {
        let isEmpty = dynamicsRecords.isEmpty
        emptyContainer.isHidden = !isEmpty
        dynamicsListSurface.isHidden = isEmpty
        publishNavButton.isHidden = isEmpty
        if !isEmpty {
            view.layoutIfNeeded()
        }
    }

    @objc private func goPublishButtonTapped() {
        openPublishDynamicsScreen()
    }

    @objc private func publishNavCapsuleTapped() {
        openPublishDynamicsScreen()
    }

    private func openPublishDynamicsScreen() {
        let vc = BHDiscoverPostPhotoViewController()
        vc.title = "发布动态"
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dynamicsRecords.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let tw = max(1, tableView.bounds.width)
        return BHMineWorldDynamicTableViewCell.rowHeight(for: dynamicsRecords[indexPath.row], tableWidth: tw)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cid = BHMineWorldDynamicTableViewCell.reuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: cid, for: indexPath) as! BHMineWorldDynamicTableViewCell
        let tw = max(1, tableView.bounds.width)
        let record = dynamicsRecords[indexPath.row]
        cell.configure(record: record, tableWidth: tw) { [weak self] idx in
            guard let self else { return }
            self.presentFullscreenImagePreview(record: record, imageSlotIndex: idx)
        }
        return cell
    }

    private func presentFullscreenImagePreview(record: BHMineWorldDynamicRecord, imageSlotIndex: Int) {
        let names = Array(record.imageFileNames.prefix(3))
        guard imageSlotIndex >= 0, imageSlotIndex < names.count else { return }
        let url = BHMineWorldDynamicStore.shared.imageFileURL(for: names[imageSlotIndex])
        guard let img = UIImage(contentsOfFile: url.path) else { return }
        let pvc = BHMineWorldImageFullscreenPreviewController(image: img)
        pvc.modalPresentationStyle = .fullScreen
        present(pvc, animated: true)
    }
}

private final class BHMineWorldImageFullscreenPreviewController: UIViewController, UIGestureRecognizerDelegate {

    private let displayedImage: UIImage
    private let previewImageView = UIImageView()
    private let closeButton = UIButton(type: .custom)
    private let backgroundDismissTap = UITapGestureRecognizer()

    init(image: UIImage) {
        self.displayedImage = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        previewImageView.image = displayedImage
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isUserInteractionEnabled = true
        view.addSubview(previewImageView)

        let circle = kScaleW(36)
        closeButton.bounds = CGRect(x: 0, y: 0, width: circle, height: circle)
        closeButton.layer.cornerRadius = circle / 2
        closeButton.layer.masksToBounds = true
        closeButton.backgroundColor = .white
        let cfg = UIImage.SymbolConfiguration(pointSize: kScaleW(15), weight: .semibold)
        let xIcon = UIImage(systemName: "xmark", withConfiguration: cfg)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        closeButton.setImage(xIcon, for: .normal)
        closeButton.adjustsImageWhenHighlighted = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        backgroundDismissTap.addTarget(self, action: #selector(closeTapped))
        backgroundDismissTap.delegate = self
        view.addGestureRecognizer(backgroundDismissTap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewImageView.frame = view.bounds
        let circle = closeButton.bounds.width
        guard circle > 0 else { return }
        let sideMargin = kScaleW(16)
        let topExtra = kScaleW(8)
        let xPos = view.bounds.width - circle - sideMargin
        let yPos = view.safeAreaInsets.top + topExtra
        closeButton.frame = CGRect(x: xPos, y: yPos, width: circle, height: circle)
        view.bringSubviewToFront(closeButton)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl {
            return false
        }
        return true
    }
}
