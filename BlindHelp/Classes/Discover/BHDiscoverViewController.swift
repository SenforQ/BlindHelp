//
//  BHDiscoverViewController.swift
//  BlindHelp
//

import UIKit

private struct BHDiscoverTopicItem {

    let imageNamed: String

    let title: String

    let subtitle: String
}

private final class BHDiscoverTopicMiniCell: UIView {

    var onTopicTapped: (() -> Void)?

    let thumbImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = kScaleW(8)
        thumbImageView.backgroundColor = UIColor.kHexColor(hexString: "#EAEAEA")
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .bh_pingFang(size: kScaleW(13), weight: .medium)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .bh_pingFang(size: kScaleW(11), weight: .regular)
        subtitleLabel.textColor = UIColor.kHexColor(hexString: "#888888")
        subtitleLabel.numberOfLines = 2

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let textColumn = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textColumn.axis = .vertical
        textColumn.spacing = kScaleW(4)
        textColumn.alignment = .leading
        textColumn.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [thumbImageView, textColumn])
        row.axis = .horizontal
        row.spacing = kScaleW(8)
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        let side = kScaleW(54)
        NSLayoutConstraint.activate([
            thumbImageView.widthAnchor.constraint(equalToConstant: side),
            thumbImageView.heightAnchor.constraint(equalToConstant: side),

            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(topicPillTapped))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func topicPillTapped() {
        onTopicTapped?()
    }

    func configure(_ item: BHDiscoverTopicItem) {
        thumbImageView.image =
            UIImage(named: item.imageNamed) ?? UIImage(named: "home_top_image")
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}

/// Tab「广场」：话题区 + 每名 NPC 一张朋友圈摘要卡片（各取一条动态）。
final class BHDiscoverViewController: BHBaseViewController {

    private enum DiscoverLayout {
        /// 与 `BHMineViewController.MineLayout.topBgHeight` 一致。
        static let topBgHeight = kScaleW(240)
    }

    private lazy var topImgView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "mine_top_bg"))
        v.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: DiscoverLayout.topBgHeight)
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    private lazy var bottomTabBar: BHCustomBottomTabBarView = {
        let bar = BHCustomBottomTabBarView(host: self, selectedMainTab: .square)
        bar.onPhotoButtonTapped = { [weak self] in
            guard let nav = self?.navigationController else { return }
            nav.pushViewController(BHDiscoverPostPhotoViewController(), animated: true)
        }
        return bar
    }()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let segmentBar = UIView()
    private let squareTabButton = UIButton(type: .system)
    private let followingTabButton = UIButton(type: .system)
    private var segmentUnderline = UIView()
    private var segmentUnderlineCenterX: NSLayoutConstraint?

    private let topicsChrome = UIView()
    private let topicHeaderRow = UIView()
    private let topicTitleLabel = UILabel()
    private let topicsPager = UIScrollView()
    private let topicsPageStack = UIView()

    private let squareMomentStack = UIStackView()
    private let followingMomentStack = UIStackView()
    private let followingHintLabel = UILabel()

    private var selectedDiscoverSegmentIndex = 0

    private var topicPagesBuilt = false

    private var topicTapOrdinalSeed = 0

    private var shieldListObserverToken: BHFigureFeedHideObserverToken?

    private static func topicPaginationSource() -> [[BHDiscoverTopicItem]] {
        [
            [
                BHDiscoverTopicItem(
                    imageNamed: "man_1_2",
                    title: "美食热门话题",
                    subtitle: "来这里分享美食吧"
                ),
                BHDiscoverTopicItem(
                    imageNamed: "man_2_3",
                    title: "徒步热门话题",
                    subtitle: "晒出你的山野瞬间"
                ),
                BHDiscoverTopicItem(
                    imageNamed: "man_4_3",
                    title: "阅读热门话题",
                    subtitle: "写下今日收获"
                ),
                BHDiscoverTopicItem(
                    imageNamed: "man_5_2",
                    title: "运动热门话题",
                    subtitle: "自律让你发光"
                ),
            ],
            [
                BHDiscoverTopicItem(
                    imageNamed: "man_6_3",
                    title: "湖畔热门话题",
                    subtitle: "慢慢走也会到岸"
                ),
                BHDiscoverTopicItem(
                    imageNamed: "man_7_2",
                    title: "海岸线热门话题",
                    subtitle: "海风与晚霞都在等你"
                ),
                BHDiscoverTopicItem(
                    imageNamed: "man_3_2",
                    title: "音乐热门话题",
                    subtitle: "把你喜欢的单曲晒出来"
                ),
                BHDiscoverTopicItem(
                    imageNamed: "man_5_3",
                    title: "晚霞热门话题",
                    subtitle: "记录今日最后一道光"
                ),
            ],
        ]
    }

    override func setupBodyView() {
        kdNavBar.isHidden = true
        baseBackgroundTopImgV.isHidden = true
        baseBackgroundBodyImgV.isHidden = true
        view.backgroundColor = .kHexColor(hexString: "#F7F7F7")
        navigationItem.title = ""

        shieldListObserverToken =
            BHFigureFeedHideObserverToken { [weak self] in
                self?.reloadDiscoverFeeds()
            }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }

        contentStack.axis = .vertical
        contentStack.spacing = kScaleW(12)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.backgroundColor = .clear

        configureSegmentChrome()
        configureTopicsChrome()
        configureFollowingChrome()

        followingMomentStack.axis = .vertical
        followingMomentStack.spacing = kScaleW(12)
        followingMomentStack.alignment = .fill
        followingMomentStack.distribution = .fill
        followingMomentStack.translatesAutoresizingMaskIntoConstraints = false
        followingMomentStack.backgroundColor = .clear

        squareMomentStack.axis = .vertical
        squareMomentStack.spacing = kScaleW(12)
        squareMomentStack.alignment = .fill
        squareMomentStack.distribution = .fill
        squareMomentStack.translatesAutoresizingMaskIntoConstraints = false
        squareMomentStack.backgroundColor = .clear

        view.addSubview(topImgView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        topicsChrome.translatesAutoresizingMaskIntoConstraints = false
        followingHintLabel.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(segmentBar)
        contentStack.addArrangedSubview(topicsChrome)
        contentStack.addArrangedSubview(squareMomentStack)
        contentStack.addArrangedSubview(followingMomentStack)
        contentStack.addArrangedSubview(followingHintLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: kScaleW(6)),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -kScaleW(92)),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),

            segmentBar.heightAnchor.constraint(equalToConstant: kScaleW(48)),
            followingHintLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(220)),
            squareMomentStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -kScaleW(24)),
            squareMomentStack.centerXAnchor.constraint(equalTo: contentStack.centerXAnchor),

            followingMomentStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -kScaleW(24)),
            followingMomentStack.centerXAnchor.constraint(equalTo: contentStack.centerXAnchor),

            topicsChrome.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor, constant: kScaleW(12)),
            topicsChrome.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor, constant: -kScaleW(12)),
        ])

        reloadDiscoverFeeds()
        reflectDiscoverSegmentChrome(animated: false)
        view.addSubview(bottomTabBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topImgView.frame =
            CGRect(x: 0, y: 0, width: view.bounds.width, height: DiscoverLayout.topBgHeight)
        bottomTabBar.layoutFrame(in: view.bounds)
        bh_bringCustomTabBarToFront(bottomTabBar)
        if topicsPager.bounds.width > 10, !topicPagesBuilt {
            buildTopicPagingLayoutIfNeeded(totalWidth: topicsPager.bounds.width)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomTabBar.syncHighlightedSelectionWithHostingTabBar()
        reloadDiscoverFeeds()
    }

    private func configureSegmentChrome() {
        segmentBar.backgroundColor = UIColor.white.withAlphaComponent(0.78)
        segmentBar.layer.cornerRadius = kScaleW(10)
        segmentBar.layer.masksToBounds = true
        squareTabButton.setTitle("广场", for: .normal)
        followingTabButton.setTitle("关注", for: .normal)
        squareTabButton.tag = 0
        followingTabButton.tag = 1
        squareTabButton.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        followingTabButton.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)

        segmentUnderline.backgroundColor = UIColor.kHexColor(hexString: "#A6F500")
        segmentUnderline.layer.cornerRadius = kScaleW(2)
        segmentUnderline.layer.masksToBounds = true

        [squareTabButton, followingTabButton].forEach { btn in
            btn.titleLabel?.font = .bh_pingFang(size: kScaleW(17), weight: .regular)
            btn.setTitleColor(UIColor.kHexColor(hexString: "#AAAAAA"), for: .normal)
            btn.translatesAutoresizingMaskIntoConstraints = false
            segmentBar.addSubview(btn)
        }
        segmentBar.addSubview(segmentUnderline)
        segmentUnderline.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            squareTabButton.leadingAnchor.constraint(equalTo: segmentBar.leadingAnchor, constant: kScaleW(24)),
            squareTabButton.centerYAnchor.constraint(equalTo: segmentBar.centerYAnchor),

            followingTabButton.leadingAnchor.constraint(equalTo: squareTabButton.trailingAnchor, constant: kScaleW(28)),
            followingTabButton.centerYAnchor.constraint(equalTo: segmentBar.centerYAnchor),
            segmentUnderline.widthAnchor.constraint(equalToConstant: kScaleW(28)),
            segmentUnderline.heightAnchor.constraint(equalToConstant: kScaleW(3)),
            segmentUnderline.topAnchor.constraint(equalTo: squareTabButton.bottomAnchor, constant: kScaleW(4)),
        ])
        segmentUnderlineCenterX = segmentUnderline.centerXAnchor.constraint(equalTo: squareTabButton.centerXAnchor)
        segmentUnderlineCenterX?.isActive = true
    }

    private func configureTopicsChrome() {
        topicsChrome.backgroundColor = UIColor.white
        topicsChrome.layer.cornerRadius = kScaleW(14)
        topicsChrome.layer.masksToBounds = true

        let hashCircle = UIView()
        hashCircle.layer.cornerRadius = kScaleW(15)
        hashCircle.layer.masksToBounds = true
        hashCircle.backgroundColor = UIColor.kHexColor(hexString: "#FFE8CB")
        hashCircle.translatesAutoresizingMaskIntoConstraints = false

        let hashIconCfg = UIImage.SymbolConfiguration(pointSize: kScaleW(15), weight: .semibold)
        let hashIcon = UIImageView(
            image: UIImage(systemName: "number.circle.fill", withConfiguration: hashIconCfg))
        hashIcon.translatesAutoresizingMaskIntoConstraints = false
        hashIcon.tintColor = UIColor.kHexColor(hexString: "#FF8C00")
        hashCircle.addSubview(hashIcon)

        topicTitleLabel.font = .bh_pingFang(size: kScaleW(16), weight: .bold)
        topicTitleLabel.textColor = .black
        topicTitleLabel.text = "话题"
        topicTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        topicHeaderRow.translatesAutoresizingMaskIntoConstraints = false
        topicsChrome.addSubview(topicHeaderRow)

        topicHeaderRow.addSubview(hashCircle)
        topicHeaderRow.addSubview(topicTitleLabel)

        NSLayoutConstraint.activate([
            hashCircle.leadingAnchor.constraint(equalTo: topicHeaderRow.leadingAnchor),
            hashCircle.centerYAnchor.constraint(equalTo: topicHeaderRow.centerYAnchor),
            hashCircle.widthAnchor.constraint(equalToConstant: kScaleW(30)),
            hashCircle.heightAnchor.constraint(equalToConstant: kScaleW(30)),

            hashIcon.centerXAnchor.constraint(equalTo: hashCircle.centerXAnchor),
            hashIcon.centerYAnchor.constraint(equalTo: hashCircle.centerYAnchor),

            topicTitleLabel.leadingAnchor.constraint(equalTo: hashCircle.trailingAnchor, constant: kScaleW(8)),
            topicTitleLabel.centerYAnchor.constraint(equalTo: topicHeaderRow.centerYAnchor),
            topicTitleLabel.trailingAnchor.constraint(equalTo: topicHeaderRow.trailingAnchor),

            topicHeaderRow.heightAnchor.constraint(equalToConstant: kScaleW(36)),
        ])

        topicsPager.isPagingEnabled = true
        topicsPager.showsHorizontalScrollIndicator = false
        topicsPager.translatesAutoresizingMaskIntoConstraints = false

        topicsPageStack.translatesAutoresizingMaskIntoConstraints = false
        topicsPager.addSubview(topicsPageStack)

        topicsChrome.addSubview(topicsPager)

        NSLayoutConstraint.activate([
            topicHeaderRow.leadingAnchor.constraint(equalTo: topicsChrome.leadingAnchor, constant: kScaleW(14)),
            topicHeaderRow.trailingAnchor.constraint(equalTo: topicsChrome.trailingAnchor, constant: -kScaleW(14)),
            topicHeaderRow.topAnchor.constraint(equalTo: topicsChrome.topAnchor, constant: kScaleW(10)),

            topicsPager.topAnchor.constraint(equalTo: topicHeaderRow.bottomAnchor, constant: kScaleW(12)),
            topicsPager.leadingAnchor.constraint(equalTo: topicsChrome.leadingAnchor, constant: kScaleW(10)),
            topicsPager.trailingAnchor.constraint(equalTo: topicsChrome.trailingAnchor, constant: -kScaleW(10)),
            topicsPager.bottomAnchor.constraint(equalTo: topicsChrome.bottomAnchor, constant: -kScaleW(8)),
        ])
    }

    private func buildTopicPagingLayoutIfNeeded(totalWidth: CGFloat) {
        guard totalWidth > 10, !topicPagesBuilt else { return }
        topicPagesBuilt = true
        topicTapOrdinalSeed = 0
        let pagesData = Self.topicPaginationSource()

        topicsPageStack.subviews.forEach { $0.removeFromSuperview() }

        topicsPageStack.widthAnchor.constraint(equalToConstant: totalWidth * CGFloat(pagesData.count)).isActive = true
        topicsPageStack.topAnchor.constraint(equalTo: topicsPager.topAnchor).isActive = true
        topicsPageStack.bottomAnchor.constraint(equalTo: topicsPager.bottomAnchor).isActive = true
        topicsPageStack.leadingAnchor.constraint(equalTo: topicsPager.leadingAnchor).isActive = true
        topicsPageStack.heightAnchor.constraint(equalTo: topicsPager.heightAnchor).isActive = true

        var previousAnchor: UIView?
        for (_, pageTopics) in pagesData.enumerated() {
            let pageView = UIView()
            pageView.translatesAutoresizingMaskIntoConstraints = false

            topicsPageStack.addSubview(pageView)

            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: topicsPageStack.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: topicsPageStack.bottomAnchor),
                pageView.widthAnchor.constraint(equalToConstant: totalWidth),
            ])

            if let prev = previousAnchor {
                pageView.leadingAnchor.constraint(equalTo: prev.trailingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: topicsPageStack.leadingAnchor).isActive = true
            }
            previousAnchor = pageView

            let cellHStackTop = UIStackView()
            let cellHStackBottom = UIStackView()

            func buildRow(_ slice: ArraySlice<BHDiscoverTopicItem>, into row: UIStackView) {
                row.axis = .horizontal
                row.spacing = kScaleW(10)
                row.distribution = .fillEqually
                row.translatesAutoresizingMaskIntoConstraints = false
                for ti in slice {
                    let pill = BHDiscoverTopicMiniCell()
                    let ordinal = topicTapOrdinalSeed
                    topicTapOrdinalSeed += 1
                    pill.configure(ti)
                    pill.onTopicTapped = { [weak self] in
                        self?.openHuatiDetail(item: ti, ordinal: ordinal)
                    }
                    row.addArrangedSubview(pill)
                }
            }

            buildRow(pageTopics[..<((pageTopics.count / 2))], into: cellHStackTop)
            buildRow(pageTopics[(pageTopics.count / 2)...], into: cellHStackBottom)

            let col = UIStackView(arrangedSubviews: [cellHStackTop, cellHStackBottom])
            col.axis = .vertical
            col.spacing = kScaleW(12)
            col.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(col)

            NSLayoutConstraint.activate([
                col.topAnchor.constraint(equalTo: pageView.topAnchor, constant: kScaleW(2)),
                col.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: kScaleW(4)),
                col.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -kScaleW(4)),
                col.bottomAnchor.constraint(equalTo: pageView.bottomAnchor, constant: -kScaleW(2)),
            ])
        }

        if let anchor = previousAnchor {
            anchor.trailingAnchor.constraint(equalTo: topicsPageStack.trailingAnchor).isActive = true
        }

        let pagerHeight = topicsPager.heightAnchor.constraint(equalToConstant: kScaleW(180))
        pagerHeight.priority = UILayoutPriority(999)
        pagerHeight.isActive = true

        topicsPager.layoutIfNeeded()
    }

    private func configureMomentInteractionHandlers(_ card: BHMomentFeedCardView) {
        card.onMomentLikeRefresh = { [weak card] in
            card?.layoutIfNeeded()
        }
        card.onMomentMoreActions = { [weak self] button, fid, nickname in
            self?.presentFigureMoreSheet(source: button, figureId: fid, displayName: nickname)
        }
        card.onMomentAvatarTap = { [weak self] fid in
            self?.presentFigureHome(figureId: fid)
        }
    }

    private func configureFollowingChrome() {
        followingHintLabel.font = .bh_pingFang(size: kScaleW(14), weight: .medium)
        followingHintLabel.textColor = UIColor.kHexColor(hexString: "#999999")
        followingHintLabel.textAlignment = .center
        followingHintLabel.numberOfLines = 4
        followingHintLabel.text = "暂时没有关注的好友动态\n去发现页逛逛吧～"
        followingHintLabel.adjustsFontSizeToFitWidth = true
        followingHintLabel.minimumScaleFactor = 0.92
        followingHintLabel.isHidden = true
    }

    private func reloadDiscoverFeeds() {
        reloadSquareFeedPresentation()
        reloadFollowingFeedPresentation()
    }

    private func reloadSquareFeedPresentation() {
        topicsChrome.isHidden = selectedDiscoverSegmentIndex != 0

        let models = BHDiscoverViewController.modelsForSquareFeedOneMomentPerFigure()
        squareMomentStack.arrangedSubviews.forEach { v in
            squareMomentStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for item in models {
            let card = BHMomentFeedCardView()
            configureMomentInteractionHandlers(card)
            card.configure(model: item)
            squareMomentStack.addArrangedSubview(card)
        }

        let showSquareFeed = selectedDiscoverSegmentIndex == 0 && !models.isEmpty
        squareMomentStack.isHidden = !showSquareFeed
    }

    private func reloadFollowingFeedPresentation() {
        let models = BHDiscoverViewController.modelsForFollowingFeedDisplay()
        followingMomentStack.arrangedSubviews.forEach { v in
            followingMomentStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for item in models {
            let card = BHMomentFeedCardView()
            configureMomentInteractionHandlers(card)
            card.configure(model: item)
            followingMomentStack.addArrangedSubview(card)
        }

        guard selectedDiscoverSegmentIndex == 1 else {
            followingMomentStack.isHidden = true
            followingHintLabel.isHidden = true
            return
        }

        followingMomentStack.isHidden = models.isEmpty
        followingHintLabel.isHidden = !models.isEmpty
    }

    private static func modelsForFollowingFeedDisplay() -> [BHMomentFeedCardModel] {
        var out: [BHMomentFeedCardModel] = []
        for fid in BHVideoFigureFollowStore.sortedFollowedFigureIds() {
            guard let npc = BHFigureResourceCatalog.profile(figureId: fid) else { continue }
            guard !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: fid) else { continue }
            for moment in npc.moments {
                out.append(
                    BHMomentFeedCardModel(figureId: fid, profile: npc, post: moment)
                )
            }
        }
        return out
    }

    private static func modelsForSquareFeedOneMomentPerFigure() -> [BHMomentFeedCardModel] {
        var out: [BHMomentFeedCardModel] = []
        let ordered = BHFigureResourceCatalog.allProfiles.sorted { $0.figureId < $1.figureId }
        for npc in ordered {
            guard !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: npc.figureId) else {
                continue
            }
            guard let moment = npc.moments.first else {
                continue
            }
            out.append(
                BHMomentFeedCardModel(figureId: npc.figureId, profile: npc, post: moment)
            )
        }
        return out
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        selectedDiscoverSegmentIndex = sender.tag == 1 ? 1 : 0
        reflectDiscoverSegmentChrome(animated: true)
        reloadDiscoverFeeds()
    }

    private func reflectDiscoverSegmentChrome(animated: Bool) {
        let sqOn = selectedDiscoverSegmentIndex == 0

        let fontRefresh = {
            self.squareTabButton.titleLabel?.font = self.bh_fontForSegment(active: sqOn)
            self.followingTabButton.titleLabel?.font = self.bh_fontForSegment(active: !sqOn)
            self.squareTabButton.setTitleColor(
                sqOn ? .black : UIColor.kHexColor(hexString: "#AAAAAA"),
                for: .normal
            )
            self.followingTabButton.setTitleColor(
                sqOn ? UIColor.kHexColor(hexString: "#AAAAAA") : .black,
                for: .normal
            )
            self.segmentUnderlineCenterX?.isActive = false
            let target = sqOn ? self.squareTabButton : self.followingTabButton
            self.segmentUnderlineCenterX =
                self.segmentUnderline.centerXAnchor.constraint(equalTo: target.centerXAnchor)
            self.segmentUnderlineCenterX?.isActive = true
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                fontRefresh()
                self.segmentBar.layoutIfNeeded()
            }
        } else {
            UIView.performWithoutAnimation {
                fontRefresh()
                self.segmentBar.layoutIfNeeded()
            }
        }
    }

    private func bh_fontForSegment(active: Bool) -> UIFont {
        .bh_pingFang(size: kScaleW(17), weight: active ? .medium : .regular)
    }

    private func presentFigureMoreSheet(source: UIButton, figureId: Int, displayName: String) {
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
            self?.reloadDiscoverFeeds()
        })
        sheet.addAction(UIAlertAction(title: "屏蔽", style: .destructive) { [weak self] _ in
            BHFigureBlockShieldStore.shield(figureId: figureId)
            NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
            self?.view.cd_showDefaultToast("已屏蔽")
            self?.reloadDiscoverFeeds()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = source
            pop.sourceRect = source.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(sheet, animated: true)
    }

    private func presentFigureHome(figureId: Int) {
        guard let nav = navigationController else { return }
        let detail = BHDetailFigureViewController(figureId: figureId)
        nav.pushViewController(detail, animated: true)
    }

    private func openHuatiDetail(item: BHDiscoverTopicItem, ordinal: Int) {
        guard let nav = navigationController else { return }
        let vc =
            BHHuatiViewController(
                topicTitle: item.title,
                topicSubtitle: item.subtitle,
                topicOrdinalAnchor: ordinal
            )
        nav.pushViewController(vc, animated: true)
    }
}
