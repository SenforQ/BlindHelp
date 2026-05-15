//
//  BHMessageViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// Tab「消息」根页面：顶部 `mine_top_bg`、`消息 / 关注` 切换，首行固定旅行助手并列出角色私信记录。
final class BHMessageViewController: BHBaseViewController, UITableViewDelegate, UITableViewDataSource {

    private enum MessageLayout {
        static let topBgHeight = kScaleW(240)
        static let tabBarScrollClearance = kScaleW(92)
        static let segmentHeaderHeight = kScaleW(52)
        static let rowHeight = kScaleW(86)
        static let avatarSide = kScaleW(52)
    }

    private enum MessageHubSegment: Int {
        case inbox
        case following
    }

    private enum MessageHubRowKind {
        case travelAssistant
        case figure(figureId: Int)
    }

    private struct MessageHubRowModel {
        let kind: MessageHubRowKind
        let title: String
        let snippet: String
        let timeText: String
    }

    private lazy var topImgView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "mine_top_bg"))
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let segmentHost = UIView()
    private let messageTitleLabel = UILabel()
    private let followingTitleLabel = UILabel()

    private var selectedSegment = MessageHubSegment.inbox

    private var cachedRowModels: [MessageHubRowModel] = []

    /// 块观察者 token，在 `deinit` 中用 `removeObserver(_: NSObjectProtocol)` 注销。
    private var bhFigureShieldObservationToken: NSObjectProtocol?

    private lazy var bottomTabBar: BHCustomBottomTabBarView = {
        let bar = BHCustomBottomTabBarView(host: self, selectedMainTab: .message)
        bar.onPhotoButtonTapped = { [weak self] in
            guard let nav = self?.navigationController else { return }
            nav.pushViewController(BHDiscoverPostPhotoViewController(), animated: true)
        }
        return bar
    }()

    private lazy var inboxEmptyFootnote: UILabel = {
        let lab = UILabel()
        lab.numberOfLines = 2
        lab.textAlignment = .center
        lab.font = .bh_pingFang(size: kScaleW(14), weight: .medium)
        lab.textColor = UIColor.kHexColor(hexString: "#999999")
        lab.text = "还没有与其它旅友的私信记录"
        lab.isHidden = true
        return lab
    }()

    private lazy var followingEmptyFootnote: UILabel = {
        let lab = UILabel()
        lab.numberOfLines = 2
        lab.textAlignment = .center
        lab.font = .bh_pingFang(size: kScaleW(14), weight: .medium)
        lab.textColor = UIColor.kHexColor(hexString: "#999999")
        lab.text = "还没有关注的旅友\n在首页视频或资料页点「关注」吧"
        lab.isHidden = true
        return lab
    }()

    override func setupBodyView() {
        kdNavBar.isHidden = true
        baseBackgroundTopImgV.isHidden = true
        baseBackgroundBodyImgV.isHidden = true
        view.backgroundColor = UIColor.kHexColor(hexString: "#F7F7F7")

        view.addSubview(topImgView)

        configureSegmentChrome()
        buildFixedTableHeaderShell()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: kScaleW(12) + MessageLayout.avatarSide + kScaleW(12),
            bottom: 0,
            right: kScaleW(16)
        )
        tableView.separatorColor = UIColor.kHexColor(hexString: "#ECECEC")
        tableView.rowHeight = MessageLayout.rowHeight
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BHMessageConversationCell.self, forCellReuseIdentifier: BHMessageConversationCell.reuseId)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        adjustTableScrollMargins()

        view.addSubview(tableView)
        view.addSubview(bottomTabBar)
        view.addSubview(inboxEmptyFootnote)
        view.addSubview(followingEmptyFootnote)
        inboxEmptyFootnote.translatesAutoresizingMaskIntoConstraints = false
        followingEmptyFootnote.translatesAutoresizingMaskIntoConstraints = false

        bhFigureShieldObservationToken = NotificationCenter.default.addObserver(
            forName: .bhHomeFigureBlockedOrShieldedListDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildMessageListPayload()
        }
    }

    override func setupSubConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            inboxEmptyFootnote.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: kScaleW(32)),
            inboxEmptyFootnote.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -kScaleW(32)),
            inboxEmptyFootnote.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: kScaleW(48)),

            followingEmptyFootnote.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: kScaleW(32)),
            followingEmptyFootnote.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -kScaleW(32)),
            followingEmptyFootnote.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: kScaleW(48)),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topImgView.frame =
            CGRect(x: 0, y: 0, width: view.bounds.width, height: MessageLayout.topBgHeight)
        view.sendSubviewToBack(topImgView)
        bh_pinTableSegmentHeader(width: tableView.bounds.width)
        adjustTableScrollMargins()
        bottomTabBar.layoutFrame(in: view.bounds)
        bh_bringCustomTabBarToFront(bottomTabBar)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomTabBar.syncHighlightedSelectionWithHostingTabBar()
        rebuildMessageListPayload()
    }

    @MainActor deinit {
        if let tok = bhFigureShieldObservationToken {
            NotificationCenter.default.removeObserver(tok)
        }
        bhFigureShieldObservationToken = nil
    }

    private func adjustTableScrollMargins() {
        let c = MessageLayout.tabBarScrollClearance
        tableView.contentInset.bottom = c
        tableView.verticalScrollIndicatorInsets.bottom = c
    }

    private func configureSegmentChrome() {
        segmentHost.backgroundColor = .clear
        segmentHost.frame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: MessageLayout.segmentHeaderHeight
        )

        messageTitleLabel.text = "消息"
        followingTitleLabel.text = "关注"

        messageTitleLabel.isUserInteractionEnabled = true
        followingTitleLabel.isUserInteractionEnabled = true

        messageTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedInboxSegment)))
        followingTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedFollowingSegment)))

        [messageTitleLabel, followingTitleLabel].forEach { lab in
            lab.translatesAutoresizingMaskIntoConstraints = false
            segmentHost.addSubview(lab)
        }

        NSLayoutConstraint.activate([
            messageTitleLabel.leadingAnchor.constraint(equalTo: segmentHost.leadingAnchor, constant: kScaleW(18)),
            messageTitleLabel.topAnchor.constraint(equalTo: segmentHost.topAnchor, constant: kScaleW(8)),
            messageTitleLabel.bottomAnchor.constraint(equalTo: segmentHost.bottomAnchor, constant: -kScaleW(10)),

            followingTitleLabel.leadingAnchor.constraint(equalTo: messageTitleLabel.trailingAnchor, constant: kScaleW(20)),
            followingTitleLabel.firstBaselineAnchor.constraint(equalTo: messageTitleLabel.firstBaselineAnchor),
        ])

        reflectSegmentTitles()
    }

    private func buildFixedTableHeaderShell() {
        let wrap = UIView()
        wrap.backgroundColor = .clear
        wrap.addSubview(segmentHost)
        segmentHost.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentHost.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            segmentHost.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            segmentHost.topAnchor.constraint(equalTo: wrap.topAnchor),
            segmentHost.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            segmentHost.heightAnchor.constraint(equalToConstant: MessageLayout.segmentHeaderHeight),
        ])
        let w = view.bounds.width > 10 ? view.bounds.width : UIScreen.main.bounds.width
        wrap.frame = CGRect(x: 0, y: 0, width: w, height: MessageLayout.segmentHeaderHeight)
        wrap.layoutIfNeeded()
        tableView.tableHeaderView = wrap
    }

    private func bh_pinTableSegmentHeader(width: CGFloat) {
        guard let hv = tableView.tableHeaderView, width > 10 else { return }
        let h = MessageLayout.segmentHeaderHeight
        if abs(hv.bounds.width - width) < 1, abs(hv.bounds.height - h) < 1 {
            return
        }
        var f = hv.frame
        f.size.width = width
        f.size.height = h
        hv.frame = f
        tableView.tableHeaderView = hv
    }

    @objc private func tappedInboxSegment() {
        setSegment(MessageHubSegment.inbox)
    }

    @objc private func tappedFollowingSegment() {
        setSegment(MessageHubSegment.following)
    }

    private func setSegment(_ seg: MessageHubSegment) {
        guard seg != selectedSegment else { return }
        selectedSegment = seg
        reflectSegmentTitles()
        rebuildMessageListPayload()
    }

    private func reflectSegmentTitles() {
        let inboxOn = selectedSegment == .inbox
        let titleFontBold = UIFont.bh_pingFang(size: kScaleW(21), weight: .bold)
        let titleFontLight = UIFont.bh_pingFang(size: kScaleW(21), weight: .regular)

        messageTitleLabel.font = inboxOn ? titleFontBold : titleFontLight
        followingTitleLabel.font = inboxOn ? titleFontLight : titleFontBold

        messageTitleLabel.textColor =
            inboxOn ? .black : UIColor.kHexColor(hexString: "#BBBBBB")
        followingTitleLabel.textColor =
            inboxOn ? UIColor.kHexColor(hexString: "#BBBBBB") : .black

        messageTitleLabel.text = "消息"
        followingTitleLabel.text = "关注"
    }

    private func rebuildMessageListPayload() {
        cachedRowModels = Self.buildModels(segment: selectedSegment)
        let inboxNonAssistant =
            cachedRowModels.filter {
                if case .travelAssistant = $0.kind { return false }
                return true
            }.isEmpty
        inboxEmptyFootnote.isHidden = !(selectedSegment == .inbox && inboxNonAssistant)
        followingEmptyFootnote.isHidden = !(selectedSegment == .following && cachedRowModels.isEmpty)

        UIView.performWithoutAnimation {
            tableView.reloadData()
            tableView.layoutIfNeeded()
        }
    }

    private static let travelAssistantSubtitle = "欢迎来到这里，有疑问可以问我～"

    private static func timeLabelText(epoch: TimeInterval) -> String {
        guard epoch > 0 else { return "--" }
        let date = Date(timeIntervalSince1970: epoch)
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.locale = Locale.autoupdatingCurrent
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) {
            return "昨天"
        }
        let f = DateFormatter()
        f.locale = Locale.autoupdatingCurrent
        f.dateFormat = "M/d"
        return f.string(from: date)
    }

    private static func buildModels(segment: MessageHubSegment) -> [MessageHubRowModel] {
        switch segment {
        case .inbox:
            let outboundTs = BHTravelAssistantOutboundStore.lastOutboundUnix()
            let assistantSnippet: String
            let assistantTimeEpoch: TimeInterval
            if outboundTs > 0, let outboundBody = BHTravelAssistantOutboundStore.lastOutboundBody() {
                assistantSnippet = BHMessageViewController.snippetOneLine(outboundBody)
                assistantTimeEpoch = outboundTs
            } else {
                assistantSnippet = travelAssistantSubtitle
                assistantTimeEpoch = 0
            }
            let assistantRow = MessageHubRowModel(
                kind: .travelAssistant,
                title: "旅行助手",
                snippet: assistantSnippet,
                timeText: timeLabelText(epoch: assistantTimeEpoch)
            )
            let figureIds = BHFigureChatHistoryStore.sortedMessagedFigureIdsRecentFirst()
            let figureRows =
                figureIds
                .compactMap { fid -> MessageHubRowModel? in
                    guard let profile = BHFigureResourceCatalog.profile(figureId: fid) else {
                        return nil
                    }
                    let body =
                        BHFigureChatHistoryStore.savedMessageBody(for: fid) ?? ""
                    let clipped = BHMessageViewController.snippetOneLine(body)
                    return MessageHubRowModel(
                        kind: .figure(figureId: fid),
                        title: profile.nickname,
                        snippet: clipped,
                        timeText: timeLabelText(
                            epoch: BHFigureChatHistoryStore.lastSentTimestamp(for: fid)
                        )
                    )
                }
            return [assistantRow] + figureRows
        case .following:
            let ids =
                BHVideoFigureFollowStore
                .sortedFollowedFigureIds()
                .filter { !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: $0) }
            let sortedFollow =
                ids
                .sorted { a, b in
                    let ta = BHFigureChatHistoryStore.lastSentTimestamp(for: a)
                    let tb = BHFigureChatHistoryStore.lastSentTimestamp(for: b)
                    if ta != tb { return ta > tb }
                    return a < b
                }
            return sortedFollow.compactMap { fid -> MessageHubRowModel? in
                guard let profile = BHFigureResourceCatalog.profile(figureId: fid) else {
                    return nil
                }
                let snippet: String
                if BHFigureChatHistoryStore.hasSent(for: fid),
                   let body = BHFigureChatHistoryStore.savedMessageBody(for: fid)
                {
                    snippet = BHMessageViewController.snippetOneLine(body)
                } else {
                    snippet = "发条私信，向 \(profile.nickname) 打个招呼吧"
                }

                let timePart: String
                if BHFigureChatHistoryStore.hasSent(for: fid) {
                    timePart =
                        timeLabelText(
                            epoch: BHFigureChatHistoryStore.lastSentTimestamp(for: fid)
                        )
                } else {
                    timePart = "--"
                }
                return MessageHubRowModel(
                    kind: .figure(figureId: fid),
                    title: profile.nickname,
                    snippet: snippet,
                    timeText: timePart
                )
            }
        }
    }

    private static func snippetOneLine(_ raw: String) -> String {
        let t =
            raw
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > 36 else {
            return t.isEmpty ? " " : t
        }
        let idx = t.index(t.startIndex, offsetBy: 34)
        return String(t[..<idx]) + "…"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cachedRowModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: BHMessageConversationCell.reuseId, for: indexPath)
            as! BHMessageConversationCell
        let row = cachedRowModels[indexPath.row]
        switch row.kind {
        case .travelAssistant:
            let appAvatar = UIImage(named: BHUserProfileManager.defaultAvatarAssetName)
            cell.configureNpc(
                avatar: appAvatar,
                title: row.title,
                snippet: row.snippet,
                timeText: row.timeText
            )
        case .figure(let fid):
            let img = BHFigureResourceCatalog.profile(figureId: fid)?.loadAvatarImage()
            cell.configureNpc(
                avatar: img,
                title: row.title,
                snippet: row.snippet,
                timeText: row.timeText
            )
        }
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = cachedRowModels[indexPath.row]
        switch row.kind {
        case .travelAssistant:
            navigationController?.pushViewController(BHTravelAssistantConversationViewController(), animated: true)
        case .figure(let fid):
            navigationController?.pushViewController(BHFigureMessageViewController(figureId: fid), animated: true)
        }
    }
}

private final class BHMessageConversationCell: UITableViewCell {

    static let reuseId = "BHMessageConversationCell"

    private static let avatarSide = kScaleW(52)

    private let avatarBackdrop = UIView()

    private let avatarImgView = UIImageView()

    private let titleLabel = UILabel()

    private let snippetLabel = UILabel()

    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectedBackgroundView = {
            let sel = UIView()
            sel.backgroundColor = UIColor.black.withAlphaComponent(0.04)
            return sel
        }()
        avatarBackdrop.layer.cornerRadius = Self.avatarSide / 2
        avatarBackdrop.clipsToBounds = true

        avatarImgView.contentMode = .scaleAspectFill
        avatarImgView.clipsToBounds = true
        avatarImgView.layer.cornerRadius = avatarBackdrop.layer.cornerRadius - kScaleW(1.5)

        avatarBackdrop.translatesAutoresizingMaskIntoConstraints = false
        avatarImgView.translatesAutoresizingMaskIntoConstraints = false

        avatarBackdrop.backgroundColor = UIColor.kHexColor(hexString: "#F4F4F4")

        titleLabel.font = .bh_pingFang(size: kScaleW(17), weight: .medium)
        titleLabel.textColor = .black

        snippetLabel.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
        snippetLabel.textColor = UIColor.kHexColor(hexString: "#999999")
        snippetLabel.numberOfLines = 1
        snippetLabel.lineBreakMode = .byTruncatingTail

        timeLabel.font = .bh_pingFang(size: kScaleW(13), weight: .regular)
        timeLabel.textColor = UIColor.kHexColor(hexString: "#999999")
        timeLabel.textAlignment = .right
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarBackdrop)
        avatarBackdrop.addSubview(avatarImgView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(snippetLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            avatarBackdrop.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: kScaleW(16)),
            avatarBackdrop.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarBackdrop.widthAnchor.constraint(equalToConstant: Self.avatarSide),
            avatarBackdrop.heightAnchor.constraint(equalToConstant: Self.avatarSide),

            avatarImgView.centerXAnchor.constraint(equalTo: avatarBackdrop.centerXAnchor),
            avatarImgView.centerYAnchor.constraint(equalTo: avatarBackdrop.centerYAnchor),
            avatarImgView.widthAnchor.constraint(
                equalToConstant: Self.avatarSide - kScaleW(3)
            ),
            avatarImgView.heightAnchor.constraint(
                equalToConstant: Self.avatarSide - kScaleW(3)
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: avatarBackdrop.trailingAnchor,
                constant: kScaleW(12)
            ),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: kScaleW(18)),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: timeLabel.leadingAnchor,
                constant: -kScaleW(8)
            ),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(16)),
            timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            snippetLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            snippetLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(16)),
            snippetLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -kScaleW(16)),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureNpc(
        avatar: UIImage?,
        title: String,
        snippet: String,
        timeText: String
    ) {
        if let avatar {
            avatarImgView.image = avatar
        } else {
            avatarImgView.image = UIImage(named: BHUserProfileManager.defaultAvatarAssetName)
        }
        titleLabel.text = title
        snippetLabel.text = snippet
        timeLabel.text = timeText
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImgView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImgView.layer.cornerRadius = (Self.avatarSide - kScaleW(3)) / 2
    }
}

final class BHTravelAssistantConversationViewController: BHBaseViewController, UITableViewDataSource,
    UITableViewDelegate, UITextFieldDelegate
{

    private var chatRows: [(outgoing: Bool, text: String)] = [
        (false, "欢迎来到这里，有疑问可以问我～"),
    ]

    private var isRequestingAI = false

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let inputShell = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .custom)

    override func setupBodyView() {
        baseBackgroundTopImgV.isHidden = true
        baseBackgroundBodyImgV.isHidden = true
        view.backgroundColor =
            UIColor.kHexColor(hexString: "#F2F2F7")

        kdNavBar.navTitleLab.text = "旅行助手"
        kdNavBar.isHidden = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = view.backgroundColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = kScaleW(56)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(
            BHAssistantChatBalloonCell.self,
            forCellReuseIdentifier: BHAssistantChatBalloonCell.reuseId
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive

        inputShell.backgroundColor = .white
        inputShell.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        inputShell.layer.shadowOffset = CGSize(width: 0, height: -kScaleW(1))
        inputShell.layer.shadowOpacity = 1
        inputShell.layer.shadowRadius = kScaleW(2)
        inputShell.translatesAutoresizingMaskIntoConstraints = false

        inputField.font = .bh_pingFang(size: kScaleW(15), weight: .regular)
        inputField.placeholder = "向旅行助手说点什么…"
        inputField.borderStyle = .none
        inputField.textColor = .black
        inputField.backgroundColor = UIColor.kHexColor(hexString: "#F0F0F0")
        inputField.layer.cornerRadius = kScaleW(20)
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: kScaleW(14), height: 10))
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: kScaleW(14), height: 10))
        inputField.leftViewMode = .always
        inputField.rightViewMode = .always
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = .bh_pingFang(size: kScaleW(15), weight: .medium)
        sendButton.setTitleColor(.black, for: .normal)
        sendButton.layer.cornerRadius = kScaleW(20)
        sendButton.layer.masksToBounds = true
        sendButton.configuration = nil
        sendButton.backgroundColor = UIColor.kHexColor(hexString: "#A6F500")
        sendButton.adjustsImageWhenHighlighted = false
        sendButton.addTarget(self, action: #selector(sendAssistantMessageTapped), for: .touchUpInside)
        sendButton.contentEdgeInsets = UIEdgeInsets(
            top: kScaleW(8),
            left: kScaleW(16),
            bottom: kScaleW(8),
            right: kScaleW(16)
        )
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(inputShell)
        inputShell.addSubview(inputField)
        inputShell.addSubview(sendButton)
    }

    override func setupSubConstraints() {
        let kb = view.keyboardLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: kdNavBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputShell.topAnchor),

            inputShell.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputShell.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputShell.bottomAnchor.constraint(equalTo: kb.topAnchor),

            inputField.leadingAnchor.constraint(equalTo: inputShell.leadingAnchor, constant: kScaleW(14)),
            inputField.topAnchor.constraint(equalTo: inputShell.safeAreaLayoutGuide.topAnchor, constant: kScaleW(10)),
            inputField.bottomAnchor.constraint(equalTo: inputShell.safeAreaLayoutGuide.bottomAnchor, constant: -kScaleW(8)),
            inputField.heightAnchor.constraint(equalToConstant: kScaleW(42)),

            sendButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: kScaleW(10)),
            sendButton.trailingAnchor.constraint(equalTo: inputShell.trailingAnchor, constant: -kScaleW(14)),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: kScaleW(40)),
            sendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(60)),
        ])
        inputShell.heightAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(56)).isActive = true
    }

    @objc private func sendAssistantMessageTapped() {
        let text =
            inputField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        guard !text.isEmpty else {
            view.cd_showDefaultToast("请输入要发送的内容")
            return
        }
        guard !isRequestingAI else { return }

        BHTravelAssistantOutboundStore.recordOutbound(trimmedBody: text)
        chatRows.append((true, text))
        inputField.text = ""
        inputField.resignFirstResponder()
        reloadChatAndScrollToBottom(animated: false)

        isRequestingAI = true
        applySendingChrome(true)

        BHZhipuChatClient.completeChat(
            dialogue: chatRows.map { (isUser: $0.outgoing, text: $0.text) }
        ) { [weak self] result in
            guard let self else { return }
            self.isRequestingAI = false
            self.applySendingChrome(false)
            switch result {
            case .success(let englishReply):
                self.chatRows.append((false, englishReply))
                self.reloadChatAndScrollToBottom(animated: true)
            case .failure(let err):
                self.view.cd_showDefaultToast(err.localizedDescription)
            }
        }
    }

    private func applySendingChrome(_ sending: Bool) {
        sendButton.isEnabled = !sending
        inputField.isEnabled = !sending
        sendButton.alpha = sending ? 0.55 : 1
    }

    private func reloadChatAndScrollToBottom(animated: Bool) {
        tableView.reloadData()
        tableView.layoutIfNeeded()
        let last = chatRows.count - 1
        guard last >= 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: last, section: 0), at: .bottom, animated: animated)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendAssistantMessageTapped()
        return true
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatRows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: BHAssistantChatBalloonCell.reuseId,
                for: indexPath
            )
            as! BHAssistantChatBalloonCell
        let item = chatRows[indexPath.row]
        cell.apply(outgoing: item.outgoing, text: item.text)
        return cell
    }
}

private final class BHAssistantChatBalloonCell: UITableViewCell {

    static let reuseId = "BHAssistantChatBalloonCell"

    private let bubble = UIView()

    private let bodyLabel = UILabel()

    private var stackIncoming: [NSLayoutConstraint] = []

    private var stackOutgoing: [NSLayoutConstraint] = []

    private var labelEdges: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        bodyLabel.font = .bh_pingFang(size: kScaleW(15), weight: .regular)
        bodyLabel.numberOfLines = 0

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)
        bubble.addSubview(bodyLabel)

        bubble.layer.cornerRadius = kScaleW(14)
        bubble.layer.masksToBounds = true

        stackIncoming = [
            bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: kScaleW(14)),
            bubble.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -kScaleW(56)
            ),
        ]
        stackOutgoing = [
            bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(14)),
            bubble.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: kScaleW(56)
            ),
        ]
        labelEdges = [
            bodyLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: kScaleW(14)),
            bodyLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -kScaleW(14)),
            bodyLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: kScaleW(10)),
            bodyLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -kScaleW(10)),
        ]
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: kScaleW(8)),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -kScaleW(8)),
        ])
        NSLayoutConstraint.activate(labelEdges)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(outgoing: Bool, text: String) {
        bodyLabel.text = text
        NSLayoutConstraint.deactivate(stackIncoming)
        NSLayoutConstraint.deactivate(stackOutgoing)
        if outgoing {
            bubble.backgroundColor = UIColor.kHexColor(hexString: "#C8FB5A")
            bodyLabel.textColor = .black
            NSLayoutConstraint.activate(stackOutgoing)
        } else {
            bubble.backgroundColor = UIColor.white
            bodyLabel.textColor = UIColor.kHexColor(hexString: "#333333")
            NSLayoutConstraint.activate(stackIncoming)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(stackIncoming)
        NSLayoutConstraint.deactivate(stackOutgoing)
        NSLayoutConstraint.activate(stackIncoming)
        bodyLabel.text = nil
        bubble.backgroundColor = .white
        bodyLabel.textColor = UIColor.kHexColor(hexString: "#333333")
    }
}
