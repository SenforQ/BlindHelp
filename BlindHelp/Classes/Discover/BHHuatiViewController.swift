//
//  BHHuatiViewController.swift
//  BlindHelp
//

import UIKit

/// 话题详情：话题氛围头图 + 与话题绑定的确定性「打散」NPC 朋友圈列表。
final class BHHuatiViewController: BHBaseViewController {

    private let topicTitleCopy: String

    private let topicSubtitleCopy: String

    private let topicOrdinalAnchor: Int

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let topicHeaderContainerView = UIView()

    private let topicHeaderBackdropImageView = UIImageView()

    private let topicHeaderTextScrimLayer = CAGradientLayer()

    private let headerLineTitle = UILabel()

    private let headerLineSubtitle = UILabel()

    private var momentRows: [BHMomentFeedCardModel] = []

    private var shieldListObserverToken: BHFigureFeedHideObserverToken?

    private var didScrollToAnchoredHuatiSegment = false

    init(topicTitle: String, topicSubtitle: String, topicOrdinalAnchor: Int) {
        self.topicTitleCopy = topicTitle
        self.topicSubtitleCopy = topicSubtitle
        self.topicOrdinalAnchor = topicOrdinalAnchor
        super.init(nibName: nil, bundle: nil)
        title = "话题详情"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupBodyView() {
        kdNavBar.navTitleLab.text = "话题详情"
        shieldListObserverToken =
            BHFigureFeedHideObserverToken { [weak self] in
                self?.reloadMomentRowsFromPool()
            }

        baseBackgroundTopImgV.isHidden = true

        topicHeaderContainerView.backgroundColor = .clear
        topicHeaderContainerView.clipsToBounds = true

        topicHeaderBackdropImageView.image = UIImage(named: "hua_ti_image")
        topicHeaderBackdropImageView.contentMode = .scaleAspectFill
        topicHeaderBackdropImageView.clipsToBounds = true
        topicHeaderBackdropImageView.backgroundColor = .kHexColor(hexString: "#E8F5FF")
        topicHeaderBackdropImageView.translatesAutoresizingMaskIntoConstraints = false

        topicHeaderTextScrimLayer.colors = [
            UIColor.white.withAlphaComponent(0.78).cgColor,
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.clear.cgColor,
        ]
        topicHeaderTextScrimLayer.locations = [NSNumber(value: 0), NSNumber(value: 0.38), NSNumber(value: 1)]
        topicHeaderTextScrimLayer.startPoint = CGPoint(x: 0, y: 0.5)
        topicHeaderTextScrimLayer.endPoint = CGPoint(x: 1, y: 0.5)

        headerLineTitle.font = .bh_pingFang(size: kScaleW(15), weight: .medium)
        headerLineTitle.textColor = UIColor.kHexColor(hexString: "#1F2D3D")
        headerLineTitle.numberOfLines = 2

        headerLineSubtitle.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
        headerLineSubtitle.textColor = UIColor.kHexColor(hexString: "#2C3E50")
        headerLineSubtitle.numberOfLines = 5

        headerLineTitle.translatesAutoresizingMaskIntoConstraints = false
        headerLineSubtitle.translatesAutoresizingMaskIntoConstraints = false

        let titleStack = UIStackView(arrangedSubviews: [headerLineTitle, headerLineSubtitle])
        titleStack.axis = .vertical
        titleStack.spacing = kScaleW(6)
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        topicHeaderContainerView.addSubview(topicHeaderBackdropImageView)
        topicHeaderContainerView.layer.insertSublayer(topicHeaderTextScrimLayer, above: topicHeaderBackdropImageView.layer)
        topicHeaderContainerView.addSubview(titleStack)

        NSLayoutConstraint.activate([
            topicHeaderBackdropImageView.topAnchor.constraint(equalTo: topicHeaderContainerView.topAnchor),
            topicHeaderBackdropImageView.leadingAnchor.constraint(equalTo: topicHeaderContainerView.leadingAnchor),
            topicHeaderBackdropImageView.trailingAnchor.constraint(equalTo: topicHeaderContainerView.trailingAnchor),
            topicHeaderBackdropImageView.bottomAnchor.constraint(equalTo: topicHeaderContainerView.bottomAnchor),

            titleStack.leadingAnchor.constraint(equalTo: topicHeaderContainerView.leadingAnchor, constant: kScaleW(18)),
            titleStack.trailingAnchor.constraint(equalTo: topicHeaderContainerView.trailingAnchor, constant: -kScaleW(18)),
            titleStack.centerYAnchor.constraint(equalTo: topicHeaderContainerView.centerYAnchor),
            titleStack.bottomAnchor.constraint(lessThanOrEqualTo: topicHeaderContainerView.bottomAnchor, constant: -kScaleW(12)),
            titleStack.topAnchor.constraint(greaterThanOrEqualTo: topicHeaderContainerView.topAnchor, constant: kScaleW(12)),
        ])

        refreshBannerTopicAndMomentLines()

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.estimatedRowHeight = kScaleW(320)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BHHuatiMomentFeedCell.self, forCellReuseIdentifier: BHHuatiMomentFeedCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        attachTopicTableHeaderHostingView()
        view.addSubview(tableView)

        reloadMomentRowsFromPool()
    }

    /// 与设计稿一致：`hua_ti_image` 全屏宽，`211` pt 缩放高度，等比铺满裁切显示。
    private var huatiTopicBannerHeight: CGFloat { kScaleW(211) }

    private func attachTopicTableHeaderHostingView() {
        let w = tableView.bounds.width > 12 ? tableView.bounds.width : kScreenWidth
        topicHeaderContainerView.frame =
            CGRect(x: 0, y: 0, width: w, height: huatiTopicBannerHeight)
        topicHeaderContainerView.layoutIfNeeded()
        topicHeaderTextScrimLayer.frame = topicHeaderContainerView.bounds
        tableView.tableHeaderView = topicHeaderContainerView
    }

    override func setupSubConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavBarFullHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutHuatiTopicHeaderFrameIfNeeded()
        scrollToAnchoredMomentIfPossible()
    }

    private func layoutHuatiTopicHeaderFrameIfNeeded() {
        guard tableView.tableHeaderView === topicHeaderContainerView else { return }
        let w = tableView.bounds.width
        guard w > 1 else { return }
        let h = huatiTopicBannerHeight
        let host = topicHeaderContainerView
        if abs(host.frame.width - w) > 0.5 || abs(host.frame.height - h) > 0.5 {
            host.frame = CGRect(x: 0, y: 0, width: w, height: h)
            host.layoutIfNeeded()
            topicHeaderTextScrimLayer.frame = host.bounds
            tableView.tableHeaderView = host
        } else if topicHeaderTextScrimLayer.frame != host.bounds {
            topicHeaderTextScrimLayer.frame = host.bounds
        }
    }

    /// 表头文案：上行话题标题，下行与「锚定行」同一条动态的 `body`（与列表滚动锚点一致）。
    private func refreshBannerTopicAndMomentLines() {
        headerLineTitle.text = topicTitleCopy
        headerLineSubtitle.text = textForAnchoredMomentBodyFallbackTopicSubtitle()
    }

    private func textForAnchoredMomentBodyFallbackTopicSubtitle() -> String {
        guard !momentRows.isEmpty else {
            return topicSubtitleCopy
        }
        let row = anchoredRowIndex()
        guard row >= 0, row < momentRows.count else {
            return topicSubtitleCopy
        }
        let raw = momentRows[row].post.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty {
            return topicSubtitleCopy
        }
        return raw
    }

    private func reloadMomentRowsFromPool() {
        momentRows = Self.permutedVisibleMoments(topicTitle: topicTitleCopy, topicSubtitle: topicSubtitleCopy, topicOrdinal: topicOrdinalAnchor)
        tableView.reloadData()
        refreshBannerTopicAndMomentLines()
        if momentRows.isEmpty {
            tableView.backgroundView = buildEmptyMomentPlaceholderView()
            didScrollToAnchoredHuatiSegment = false
            return
        }
        tableView.backgroundView = nil
        scrollToAnchoredMomentIfPossible()
    }

    private func buildEmptyMomentPlaceholderView() -> UIView {
        let v = UIView()
        let lab = UILabel()
        lab.textAlignment = .center
        lab.numberOfLines = 2
        lab.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
        lab.textColor = UIColor.kHexColor(hexString: "#999999")
        lab.text = "暂时没有可看的话题动态"
        lab.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(lab)
        NSLayoutConstraint.activate([
            lab.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            lab.topAnchor.constraint(equalTo: v.topAnchor, constant: kScaleW(40)),
        ])
        return v
    }

    private func anchoredRowIndex() -> Int {
        guard momentRows.count > 0 else { return 0 }
        let mod = topicOrdinalAnchor % momentRows.count
        return mod < 0 ? mod + momentRows.count : mod
    }

    private func scrollToAnchoredMomentIfPossible() {
        guard !didScrollToAnchoredHuatiSegment else { return }
        guard momentRows.count > 0 else { return }
        guard tableView.bounds.height > 10 else { return }
        let row = anchoredRowIndex()
        guard row < momentRows.count else { return }
        tableView.layoutIfNeeded()
        tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: false)
        didScrollToAnchoredHuatiSegment = true
    }

    private static func fnv1a64(_ parts: String...) -> UInt64 {
        let prime: UInt64 = 1_099_511_628_211
        var hash: UInt64 = 14_695_981_039_346_656_037
        for p in parts {
            for byte in Data(p.utf8) {
                hash ^= UInt64(byte)
                hash &*= prime
            }
            hash ^= 0x7F
            hash &*= prime
        }
        return hash
    }

    private static func seededIndexShuffle(count: Int, seed seedIn: UInt64) -> [Int] {
        guard count > 0 else { return [] }
        var state = seedIn &+ 0x9E37_79B9_7F4A_7C15
        var order = Array(0..<count)
        func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            return state
        }
        var i = count - 1
        while i > 0 {
            let j = Int(next() % UInt64(i + 1))
            order.swapAt(i, j)
            i -= 1
        }
        return order
    }

    private static func flattenedVisibleMomentPool() -> [BHMomentFeedCardModel] {
        var pool: [BHMomentFeedCardModel] = []
        for npc in BHFigureResourceCatalog.allProfiles {
            guard !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: npc.figureId) else {
                continue
            }
            for moment in npc.moments {
                pool.append(BHMomentFeedCardModel(figureId: npc.figureId, profile: npc, post: moment))
            }
        }
        return pool
    }

    private static func permutedVisibleMoments(topicTitle: String, topicSubtitle: String, topicOrdinal: Int) -> [BHMomentFeedCardModel] {
        let pool = flattenedVisibleMomentPool()
        guard !pool.isEmpty else { return [] }
        var seed =
            fnv1a64(topicTitle, topicSubtitle)
            ^ UInt64(bitPattern: Int64(truncatingIfNeeded: topicOrdinal))
            ^ UInt64(truncatingIfNeeded: topicOrdinal &* 1_982_734_659)
        if seed == 0 {
            seed = 0xBADC_0FFE
        }
        let order = seededIndexShuffle(count: pool.count, seed: seed)
        let takeCount = min(32, pool.count)
        return order.prefix(takeCount).map { pool[$0] }
    }

    fileprivate func presentFigureMoreSheet(source: UIButton, figureId: Int, displayName: String) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "举报", style: .default) { [weak self] _ in
            guard let nav = self?.navigationController else {
                self?.view.cd_showDefaultToast("无法打开举报页")
                return
            }
            nav.popToRootViewController(animated: false)
            let report = BHFigureReportViewController(figureId: figureId, targetDisplayName: displayName)
            nav.pushViewController(report, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "拉黑", style: .destructive) { [weak self] _ in
            BHFigureBlockShieldStore.block(figureId: figureId)
            NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
            self?.view.cd_showDefaultToast("已拉黑")
            self?.reloadMomentRowsFromPool()
        })
        sheet.addAction(UIAlertAction(title: "屏蔽", style: .destructive) { [weak self] _ in
            BHFigureBlockShieldStore.shield(figureId: figureId)
            NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
            self?.view.cd_showDefaultToast("已屏蔽")
            self?.reloadMomentRowsFromPool()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = source
            pop.sourceRect = source.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(sheet, animated: true)
    }

    fileprivate func presentFigureHome(figureId: Int) {
        guard let nav = navigationController else { return }
        nav.pushViewController(BHDetailFigureViewController(figureId: figureId), animated: true)
    }
}

extension BHHuatiViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        momentRows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: BHHuatiMomentFeedCell.reuseIdentifier,
                for: indexPath
            ) as! BHHuatiMomentFeedCell
        cell.configure(model: momentRows[indexPath.row], host: self)
        return cell
    }
}

private final class BHHuatiMomentFeedCell: UITableViewCell {

    static let reuseIdentifier = "BHHuatiMomentFeedCell"

    private let card = BHMomentFeedCardView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: kScaleW(12)),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: kScaleW(12)),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(12)),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -kScaleW(12)),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(model: BHMomentFeedCardModel, host: BHHuatiViewController) {
        card.configure(model: model)
        card.onMomentLikeRefresh = { [weak card] in
            card?.layoutIfNeeded()
        }
        card.onMomentMoreActions = { [weak host] button, fid, nickname in
            host?.presentFigureMoreSheet(source: button, figureId: fid, displayName: nickname)
        }
        card.onMomentAvatarTap = { [weak host] fid in
            host?.presentFigureHome(figureId: fid)
        }
    }
}
