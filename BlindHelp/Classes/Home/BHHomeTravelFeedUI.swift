//
//  BHHomeTravelFeedUI.swift
//  BlindHelp
//

import UIKit

struct BHHomeTravelFeedRoot: Codable {

    struct Item: Codable {
        let tag: String
        let nickname: String
        let title: String
        let imageAssetName: String?
        let showHotBadge: Bool?
        /// 与 `BHFigureResourceCatalog.allProfiles` 中 `figureId`（1…7）对应；缺失则仅用 JSON 文案。
        let figureId: Int?
    }

    let heroItems: [Item]
    let guessYouLike: [Item]
}

extension BHHomeTravelFeedRoot.Item {

    private var linkedFigure: BHFigureNPCProfile? {
        guard let figureId else { return nil }
        return BHFigureResourceCatalog.profile(figureId: figureId)
    }

    var displayNickname: String {
        if let name = linkedFigure?.nickname {
            return name
        }
        return nickname
    }

    var displayAvatarImage: UIImage? {
        linkedFigure?.loadAvatarImage()
    }
}

struct BHHomeVideoHeroSlice {

    let tag: String
    let nickname: String
    let title: String
    let showHotBadge: Bool
    /// 若为 `nil` 则用大图占位 `home_top_image`。
    let previewImage: UIImage?
    let avatarImage: UIImage?
}

enum BHHomeTravelFeedLoader {

    static func loadDefault() -> BHHomeTravelFeedRoot {
        guard let url = Bundle.main.url(forResource: "home_travel_feed", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(BHHomeTravelFeedRoot.self, from: data)
        else {
            return BHHomeTravelFeedRoot(
                heroItems: [],
                guessYouLike: []
            )
        }
        return decoded
    }
}

extension BHHomeTravelFeedRoot {

    /// 移除已拉黑或在首页屏蔽展示的角色条目；**猜你喜欢相关列表倒序展示**。
    func excludingBlockedOrShieldedFigures() -> BHHomeTravelFeedRoot {
        func keep(_ item: Item) -> Bool {
            guard let fid = item.figureId else { return true }
            return !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: fid)
        }
        let heroes = heroItems.filter(keep)
        let guesses = guessYouLike.filter(keep)
        return BHHomeTravelFeedRoot(
            heroItems: Array(heroes.reversed()),
            guessYouLike: Array(guesses.reversed())
        )
    }
}

enum BHHomeTravelFeedReuse {
    static let gridCell = "BHHomeTravelGridCell"
    static let header = "BHHomeTravelCompositeHeader"
}

final class BHHomeTravelFeedCardShell: UIView {

    let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()

    let tagBadge = UILabel()
    let hotBadge = UILabel()
    let nicknameLabel = UILabel()
    let titleLabel = UILabel()
    private let avatarImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
        ]
        gradientLayer.locations = [0.35, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)

        tagBadge.font = .bh_pingFang(size: 11, weight: .medium)
        tagBadge.textColor = .white
        tagBadge.backgroundColor = UIColor.black.withAlphaComponent(0.38)
        tagBadge.layer.cornerRadius = kScaleW(4)
        tagBadge.layer.masksToBounds = true
        tagBadge.textAlignment = .center
        addSubview(tagBadge)

        hotBadge.text = "hot"
        hotBadge.font = .bh_pingFang(size: 10, weight: .bold)
        hotBadge.textColor = .white
        hotBadge.backgroundColor = UIColor.kHexColor(hexString: "#FF5A5F")
        hotBadge.layer.cornerRadius = kScaleW(4)
        hotBadge.layer.masksToBounds = true
        hotBadge.textAlignment = .center
        hotBadge.isHidden = true
        addSubview(hotBadge)

        nicknameLabel.font = .bh_pingFang(size: 12, weight: .regular)
        nicknameLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        addSubview(nicknameLabel)

        titleLabel.font = .bh_pingFang(size: 13, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        avatarImageView.isHidden = true
        addSubview(avatarImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(item: BHHomeTravelFeedRoot.Item, cornerRadius: CGFloat) {
        applyCore(
            cornerRadius: cornerRadius,
            tag: item.tag,
            nickname: item.displayNickname,
            title: item.title,
            showHotBadge: item.showHotBadge ?? false,
            backgroundImage: item.imageAssetName.flatMap { UIImage(named: $0) },
            avatarImage: item.displayAvatarImage
        )
    }

    func apply(videoHeroSlice: BHHomeVideoHeroSlice, cornerRadius: CGFloat) {
        let bg =
            videoHeroSlice.previewImage
            ?? UIImage(named: "home_top_image")
        applyCore(
            cornerRadius: cornerRadius,
            tag: videoHeroSlice.tag,
            nickname: videoHeroSlice.nickname,
            title: videoHeroSlice.title,
            showHotBadge: videoHeroSlice.showHotBadge,
            backgroundImage: bg,
            avatarImage: videoHeroSlice.avatarImage
        )
    }

    private func applyCore(
        cornerRadius: CGFloat,
        tag: String,
        nickname: String,
        title: String,
        showHotBadge: Bool,
        backgroundImage: UIImage?,
        avatarImage: UIImage?
    ) {
        layer.cornerRadius = cornerRadius
        imageView.layer.cornerRadius = cornerRadius

        tagBadge.text = " \(tag) "
        nicknameLabel.text = nickname
        titleLabel.text = title
        hotBadge.isHidden = !showHotBadge

        if let av = avatarImage {
            avatarImageView.image = av
            avatarImageView.isHidden = false
            avatarImageView.layer.cornerRadius = kScaleW(12)
        } else {
            avatarImageView.image = nil
            avatarImageView.isHidden = true
        }

        imageView.image = backgroundImage ?? UIImage(named: "home_top_image")

        bringSubviewToFront(tagBadge)
        bringSubviewToFront(hotBadge)
        bringSubviewToFront(avatarImageView)
        bringSubviewToFront(nicknameLabel)
        bringSubviewToFront(titleLabel)

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        gradientLayer.frame = bounds

        tagBadge.sizeToFit()
        hotBadge.sizeToFit()

        let pad = kScaleW(8)
        let tagH = max(kScaleW(20), tagBadge.bounds.height + kScaleW(6))
        tagBadge.frame = CGRect(x: pad, y: pad, width: tagBadge.bounds.width + kScaleW(10), height: tagH)

        let hotPadX = kScaleW(10)
        let hotH = kScaleW(18)
        hotBadge.frame = CGRect(
            x: bounds.width - pad - hotBadge.bounds.width - hotPadX,
            y: pad,
            width: hotBadge.bounds.width + hotPadX,
            height: hotH
        )

        let bottomTextLeft = pad
        let bottomTextRight = bounds.width - pad
        let avatarSide = kScaleW(24)
        let avatarGap = kScaleW(6)
        let showsAvatar = !avatarImageView.isHidden
        let textLeft = showsAvatar ? bottomTextLeft + avatarSide + avatarGap : bottomTextLeft
        let titleMaxW = bottomTextRight - textLeft

        titleLabel.frame = CGRect(x: textLeft, y: 0, width: titleMaxW, height: 0)
        titleLabel.sizeToFit()

        nicknameLabel.frame = CGRect(x: textLeft, y: 0, width: titleMaxW, height: kScaleW(17))
        nicknameLabel.sizeToFit()

        let stackBottom = bounds.height - pad
        titleLabel.frame.origin.y = stackBottom - titleLabel.bounds.height
        nicknameLabel.frame.origin.y = titleLabel.frame.minY - kScaleW(4) - nicknameLabel.bounds.height

        if showsAvatar {
            let nickH = max(nicknameLabel.bounds.height, kScaleW(17))
            let ay = nicknameLabel.frame.minY + (nickH - avatarSide) * 0.5
            avatarImageView.frame = CGRect(x: bottomTextLeft, y: ay, width: avatarSide, height: avatarSide)
        }
    }
}

final class BHHomeTravelCompositeHeader: UICollectionReusableView {

    /// 仅在「旅行视频」头条区域配置：`configure(videoHeroMovies:)` 后为三张卡启用点击。
    var onVideoHeroShellTapped: ((BHMovieResourceItem) -> Void)?

    private let shellLarge = BHHomeTravelFeedCardShell(frame: .zero)
    private let shellSmallTop = BHHomeTravelFeedCardShell(frame: .zero)
    private let shellSmallBottom = BHHomeTravelFeedCardShell(frame: .zero)
    private let sectionTitleLab = UILabel()
    private var videoHeroThumbnailToken = UUID()
    private var videoHeroMovieItems: [BHMovieResourceItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let crHero = kScaleW(12)
        shellLarge.layer.cornerRadius = crHero
        shellSmallTop.layer.cornerRadius = crHero
        shellSmallBottom.layer.cornerRadius = crHero

        addSubview(shellLarge)
        addSubview(shellSmallTop)
        addSubview(shellSmallBottom)

        sectionTitleLab.text = "猜你喜欢"
        sectionTitleLab.font = .bh_pingFang(size: 17, weight: .bold)
        sectionTitleLab.textColor = .kHexColor(hexString: "#000000")
        addSubview(sectionTitleLab)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stripVideoHeroShellInteractions()
        onVideoHeroShellTapped = nil
        videoHeroMovieItems = []
    }

    private func stripVideoHeroShellInteractions() {
        [shellLarge, shellSmallTop, shellSmallBottom].forEach { shell in
            shell.gestureRecognizers?.forEach { shell.removeGestureRecognizer($0) }
            shell.isUserInteractionEnabled = false
        }
    }

    func configure(hero: [BHHomeTravelFeedRoot.Item]) {
        stripVideoHeroShellInteractions()
        videoHeroMovieItems = []
        videoHeroThumbnailToken = UUID()
        sectionTitleLab.text = "猜你喜欢"
        let cr = kScaleW(12)
        if hero.count > 0 { shellLarge.apply(item: hero[0], cornerRadius: cr) }
        if hero.count > 1 { shellSmallTop.apply(item: hero[1], cornerRadius: cr) }
        if hero.count > 2 { shellSmallBottom.apply(item: hero[2], cornerRadius: cr) }
        shellLarge.isHidden = hero.count < 1
        shellSmallTop.isHidden = hero.count < 2
        shellSmallBottom.isHidden = hero.count < 3
        setNeedsLayout()
    }

    func configure(videoHeroMovies movies: [BHMovieResourceItem]) {
        stripVideoHeroShellInteractions()
        sectionTitleLab.text = "猜你喜欢"
        let token = UUID()
        videoHeroThumbnailToken = token

        let top3 = Array(movies.prefix(3))
        videoHeroMovieItems = top3
        let cr = kScaleW(12)
        shellLarge.isHidden = top3.count < 1
        shellSmallTop.isHidden = top3.count < 2
        shellSmallBottom.isHidden = top3.count < 3

        let heroTags = ["精选", "跟拍", "实况"]
        let heroTitles = [
            "把路上的每一阵风都装进镜头里。",
            "脚步慢一点，山海会自己靠过来。",
            "今天的快乐，分给屏幕前的你一半。",
        ]
        let heroHots = [true, false, false]
        let shells: [BHHomeTravelFeedCardShell] = [shellLarge, shellSmallTop, shellSmallBottom]

        for idx in 0..<top3.count {
            let shell = shells[idx]
            shell.isUserInteractionEnabled = true
            shell.tag = idx
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleVideoHeroShellTap(_:)))
            shell.addGestureRecognizer(tap)
        }

        for idx in 0..<top3.count {
            let movie = top3[idx]
            let profile = BHFigureResourceCatalog.profile(figureId: movie.figureId)
            let nickname = profile?.nickname ?? "旅行记录"
            let avatar = profile?.loadAvatarImage()
            let slice = BHHomeVideoHeroSlice(
                tag: heroTags[idx],
                nickname: nickname,
                title: heroTitles[idx],
                showHotBadge: heroHots[idx],
                previewImage: nil,
                avatarImage: avatar
            )
            shells[idx].apply(videoHeroSlice: slice, cornerRadius: cr)
        }

        for (idx, movie) in top3.enumerated() {
            BHMovieThumbnailCache.thumbnail(for: movie) { [weak self] thumb in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard self.videoHeroThumbnailToken == token else { return }
                    let profile = BHFigureResourceCatalog.profile(figureId: movie.figureId)
                    let nickname = profile?.nickname ?? "旅行记录"
                    let avatar = profile?.loadAvatarImage()
                    let slice = BHHomeVideoHeroSlice(
                        tag: heroTags[idx],
                        nickname: nickname,
                        title: heroTitles[idx],
                        showHotBadge: heroHots[idx],
                        previewImage: thumb,
                        avatarImage: avatar
                    )
                    shells[idx].apply(videoHeroSlice: slice, cornerRadius: cr)
                }
            }
        }
        setNeedsLayout()
    }

    @objc private func handleVideoHeroShellTap(_ gesture: UITapGestureRecognizer) {
        guard let v = gesture.view else { return }
        let idx = v.tag
        guard videoHeroMovieItems.indices.contains(idx) else { return }
        onVideoHeroShellTapped?(videoHeroMovieItems[idx])
    }

    static func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        let heroH = kScaleW(220)
        let titleTop = kScaleW(14)
        let titleH = kScaleW(22)
        let bottomPad = kScaleW(6)
        return heroH + titleTop + titleH + bottomPad
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let sideInset = kScaleW(14)
        let gap = kScaleW(8)
        let heroH = kScaleW(220)
        let innerW = bounds.width - sideInset * 2
        let rightColW = floor(innerW * 0.38)
        let leftColW = innerW - gap - rightColW

        shellLarge.frame = CGRect(x: sideInset, y: 0, width: leftColW, height: heroH)

        let smallH = (heroH - gap) / 2
        let rightX = sideInset + leftColW + gap
        shellSmallTop.frame = CGRect(x: rightX, y: 0, width: rightColW, height: smallH)
        shellSmallBottom.frame = CGRect(x: rightX, y: smallH + gap, width: rightColW, height: smallH)

        sectionTitleLab.frame = CGRect(
            x: sideInset,
            y: heroH + kScaleW(14),
            width: bounds.width - sideInset * 2,
            height: kScaleW(22)
        )
    }
}

final class BHHomeTravelGridCell: UICollectionViewCell {

    private let shell = BHHomeTravelFeedCardShell(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(shell)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(item: BHHomeTravelFeedRoot.Item) {
        shell.apply(item: item, cornerRadius: kScaleW(12))
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shell.frame = contentView.bounds
    }
}

// MARK: - Popular places ( UITableView )

/// 首页「热门地点」列表展示的中国精选景点条目。
struct BHPopularChinaSpot {

    let attractionTitle: String
    let locationLine: String
    let ratingDisplay: String
    let strategyBrief: String
    let coverImageAssetName: String
    let linkedFigureId: Int?
}

enum BHPopularChinaSpotCatalog {

    private static let allSpots: [BHPopularChinaSpot] = [
        BHPopularChinaSpot(
            attractionTitle: "云冈石窟",
            locationLine: "中国 | 山西省 大同市",
            ratingDisplay: "4.9",
            strategyBrief:
                "北魏皇家石窟世界遗产，提前预约讲解更能读懂造像与开凿史；夜游灯光季与悬空寺、华严寺可作晋北连线。",
            coverImageAssetName: "man_1_2",
            linkedFigureId: 1
        ),
        BHPopularChinaSpot(
            attractionTitle: "橘子洲头",
            locationLine: "中国 | 湖南省 长沙市",
            ratingDisplay: "4.9",
            strategyBrief:
                "湘江中的城市绿洲，瞻仰青年毛泽东艺术雕塑，黄昏沿江骑行；与岳麓山书院、步行街可安排一日游。",
            coverImageAssetName: "man_2_2",
            linkedFigureId: 2
        ),
        BHPopularChinaSpot(
            attractionTitle: "黄鹤楼",
            locationLine: "中国 | 湖北省 武汉市",
            ratingDisplay: "4.9",
            strategyBrief:
                "蛇山地标登楼远望长江两岸，晴川阁、长江大桥步行可达；夜游灯光与江滩轮渡体验江城夜景更佳。",
            coverImageAssetName: "man_3_2",
            linkedFigureId: 3
        ),
        BHPopularChinaSpot(
            attractionTitle: "故宫博物院",
            locationLine: "中国 | 北京市 东城区",
            ratingDisplay: "4.9",
            strategyBrief:
                "沿中轴线参观三大殿珍宝馆钟表馆为宜，实名制分上下午场；天坛景山可作同日轻装步行补充。",
            coverImageAssetName: "man_4_2",
            linkedFigureId: 4
        ),
        BHPopularChinaSpot(
            attractionTitle: "莫高窟",
            locationLine: "中国 | 甘肃省 酒泉市 敦煌市",
            ratingDisplay: "4.9",
            strategyBrief:
                "丝路世界文化遗产，务必按票面时段参观并保持窟内禁拍静音；同日可错峰鸣沙山月牙泉观景与骑驼体验。",
            coverImageAssetName: "man_5_2",
            linkedFigureId: 5
        ),
        BHPopularChinaSpot(
            attractionTitle: "峨眉山",
            locationLine: "中国 | 四川省 乐山市",
            ratingDisplay: "4.8",
            strategyBrief:
                "佛家名山云海日出盛景，山脚报国寺至金顶可分两天适应海拔；备好防风保暖与晕车药，善用观光车索道。",
            coverImageAssetName: "man_6_2",
            linkedFigureId: 6
        ),
        BHPopularChinaSpot(
            attractionTitle: "丽江古城",
            locationLine: "中国 | 云南省 丽江市",
            ratingDisplay: "4.9",
            strategyBrief:
                "纳西石板巷小桥流水，木府忠义市场感受在地生活；泸沽湖玉龙雪山需单独留日车程，初入高原注意休息补水。",
            coverImageAssetName: "man_7_2",
            linkedFigureId: 7
        ),
    ]

    static func visibleSpotsForHomeFeed() -> [BHPopularChinaSpot] {
        let kept = allSpots.filter { spot in
            guard let id = spot.linkedFigureId else { return true }
            return !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: id)
        }
        return Array(kept.reversed())
    }
}

enum BHPopularChinaSpotTravelGuide {

    static func detailSections(for spot: BHPopularChinaSpot) -> [(heading: String, body: String)] {
        guard let id = spot.linkedFigureId else {
            return [("攻略提要", spot.strategyBrief)]
        }
        let core: [(String, String)]
        switch id {
        case 1:
            core = yungangGrottoes()
        case 2:
            core = orangeIsle()
        case 3:
            core = yellowCraneTower()
        case 4:
            core = forbiddenCity()
        case 5:
            core = mogaoCaves()
        case 6:
            core = emeiMountain()
        case 7:
            core = lijiangOldTown()
        default:
            return [("攻略提要", spot.strategyBrief)]
        }
        return core
    }

    private static func yungangGrottoes() -> [(String, String)] {
        [
            (
                "行前与预约",
                "云冈石窟实行分时预约，旺季与节假日名额紧俏，建议提前在官方渠道锁定时段。大同秋冬季节风大干燥，备保暖外套与保湿；夏季紫外线强，防晒与补水同样重要。若计划深度参观，可预约官方或讲解机构人工讲解，比自行浏览更能理解北魏造像与窟形演变。"
            ),
            (
                "经典参观动线",
                "通常从东部早期窟区向西部晚期窟区推进，可感受从西域风格向中原风格过渡的雕刻语言。重点窟一般集中在中西段，留意开放政策与拍摄规定，窟内通常禁止闪光灯与长时间录像。参观节奏宜「慢看少停」，减少堵在窟口影响他人通行。"
            ),
            (
                "周边联动",
                "晋北线常见组合为云冈—华严寺—善化寺—古城墙夜景；若时间充裕，可安排浑源悬空寺与应县木塔一日往返。自驾注意山区路段天气，包车或动车+出租组合亦较省心。"
            ),
            (
                "实用提示",
                "穿防滑舒适的步行鞋，台阶与坡道较多。携带轻薄外套应对窟内外温差。尊重宗教场所礼仪，勿触摸造像。餐饮可回古城或万达商圈，刀削面与羊杂为地方特色但偏油辣，肠胃敏感者适量尝试。"
            ),
        ]
    }

    private static func orangeIsle() -> [(String, String)] {
        [
            (
                "行前与开放时间",
                "橘子洲地处湘江中部，晴雨天气温差明显，夜游与骑行非常普遍，备好防风外层与移动电源。法定节假日人流大，地铁站点可能限流；尽量错峰上午入场或雨后傍晚散步，步行距离长，轻装与舒适鞋必选。"
            ),
            (
                "岛上怎么玩",
                "青年毛泽东艺术雕塑为核心打卡点，沿岸绿道适合慢跑与骑行租借。可把「洲头瞻仰—江畔步道—焰火广场（如有活动）」串成环线。夏季注意驱蚊与中暑，江边风大时注意帽子与披肩固定。"
            ),
            (
                "与城市联动",
                "与岳麓书院、大学城、岳麓山可分午前登山午后洲头观景；步行街与太平老街适合晚间用餐。地铁跨江便捷，跨城高铁旅客优先选地铁+步行，减少路面拥堵。"
            ),
            (
                "饮食与休息",
                "长沙辣度偏高，首次尝试可选微辣并配酸奶或豆奶。景点周边便利店与咖啡较多，建议自带水壶。摄影尊重他人与军事管理区域提示，勿飞无人机于禁飞区。"
            ),
        ]
    }

    private static func yellowCraneTower() -> [(String, String)] {
        [
            (
                "预约与体力",
                "黄鹤楼与蛇山步行区域台阶较多，长幼同行建议放慢节奏与分段休息。节假日登楼排队明显，早场或工作日体验更好。关注官方公告了解夜场灯光与演出安排，夜登楼风大需外套。"
            ),
            (
                "楼上楼下怎么看",
                "电梯与步行通道可能分流，登顶层前可在中层平台阅读展陈了解诗词与重建史。江面雾天能见度低，摄影可改拍建筑细节与园林配景。下楼后可顺江滩步道远眺大桥与晴川阁方向。"
            ),
            (
                "步行半径",
                "长江大桥观景、户部巷（人流与小吃密集）、昙华林文艺街区可择一二串线，避免一日塞满。轮渡与江滩夜景别有趣味，冬季江风刺骨注意保暖。"
            ),
            (
                "旅行礼仪",
                "观景平台勿拥堵推搡，勿跨越护栏。武汉夏季湿热、冬季阴冷，雨具常备。辣油热干面份量足，可分食减少浪费。"
            ),
        ]
    }

    private static func forbiddenCity() -> [(String, String)] {
        [
            (
                "实名制与入宫窗口",
                "故宫全面实行网络预约与有效证件核验，淡季与旺季放票节奏不同，建议提前锁定上午或下午场次并按时入宫。正门安检排队较长，违禁品请勿携带大包与自拍杆（以现场告示为准）。"
            ),
            (
                "中轴线经典线",
                "午门—太和殿中和殿保和殿—乾清宫坤宁宫一线适合首次到访；钟表馆、珍宝馆需额外购票也值得安排。翊坤宫延禧宫一带展陈常与影视热点相关，人流量大时改走东侧路线更顺畅。"
            ),
            (
                "时间管理",
                "故宫面积大、纯步行耗体力，老人和儿童规划半日精华线即可，午门入内后可在冰窖餐厅附近补水休息。出神武门可调景山万春亭鸟瞰中轴，天坛可作为同日后半段但需独立预约。"
            ),
            (
                "安全与观展礼仪",
                "台阶与门槛多，注意脚下。勿触摸展柜与古建木石构件。冬季风大，夏季暴晒，帽子防晒与外套分层穿着。周边打车高峰难，可提前预约或改地铁。"
            ),
        ]
    }

    private static func mogaoCaves() -> [(String, String)] {
        [
            (
                "门票与场次",
                "莫高窟执行严格网络预约与票面参观时段，电影中心与 Shuttle 接驳需留出buffer。淡季风沙尘偶发，护目镜与口罩很实用。窟内恒定禁止闪光灯与触摸屏，讲解员带领进出，掉队可能影响参观完整性。"
            ),
            (
                "丝路艺术看点",
                "关注不同时期壁画色彩与晕染技法变化，听讲时留意「中心塔柱窟」与普通禅窟的差别。藏经洞相关展陈可帮助理解近现代流散与研究史。窟外陈列中心可补看复制窟与高精度数字化成果。"
            ),
            (
                "敦煌一日组合",
                "鸣沙山月牙泉宜放在清晨或日落，沙丘防晒与防尘同样重要；骑骆驼与电瓶车属可选付费项目。阳关玉门关单程车程较远，根据体力与车况二选一更从容。"
            ),
            (
                "高原与环境",
                "敦煌昼夜温差大且干燥，润唇膏与高保湿乳霜必备。旺季酒店提前订，夜间沙洲夜市热闹但注意饮食卫生。航拍与露营须遵守保护区规定。"
            ),
        ]
    }

    private static func emeiMountain() -> [(String, String)] {
        [
            (
                "海拔与节律",
                "峨眉山景区垂直落差大，金顶可能出现低温与瞬时雾气，备好分层保暖与雨披。易发高反与晕车者提前减量饮食、常备晕车药；索道与巴士衔接关注末班时刻，避免因排队错过下山。"
            ),
            (
                "路线取舍",
                "经典组合为山脚报国寺—雷洞坪巴士—接引殿索道—金顶观日出云海；两日行程可拆分中山段徒步与古寺巡礼。猕猴区域勿手提塑料袋晃荡，保持距离勿投喂挑衅。"
            ),
            (
                "法务与礼节",
                "寺庙内燃香明火须遵守管理规定，静默区域降低音量；捐赠与功德量力而行。冬季路面结冰时穿抓地力强的靴子，携带简易冰爪更稳妥。"
            ),
            (
                "补给与防滑",
                "中山段也有不少餐饮点，仍可自带能量棒与保温杯。下雨天台阶湿滑，下山尽量扶栏缓行；摄影设备注意防寒防潮。"
            ),
        ]
    }

    private static func lijiangOldTown() -> [(String, String)] {
        [
            (
                "古城节奏",
                "丽江古城石板路起伏且雨天湿滑，拉杆箱改背包或旅店寄存更省力。清晨巷弄安静适合拍照与散步，白日旅行团多时改走侧边小巷。四方街周边酒吧街夜间喧哗，带娃或浅眠者可择远离主街的客栈。"
            ),
            (
                "木府与市场",
                "木府与中轴线巷道人文故事丰富，可按导览循序参观。忠义市场是观察本地生活节奏与采购水果小吃的好去处，货比三家并注意过敏原。牦牛火锅与腊排骨火锅人气高，根据口味选择清汤或微辣汤底。"
            ),
            (
                "泸沽湖与雪山规划",
                "泸沽湖车程长，两日一夜更从容；玉龙雪山索道票与进山费需提前预约并关注大风停运信息。初入高原前几日避免酗酒与剧烈运动，注意补水与高糖零食应对低血糖。"
            ),
            (
                "环保与肖像",
                "古城净水河道请勿抛掷垃圾；雪山药用植物勿随意采摘。街拍若涉及当地居民与儿童宜先征询同意。"
            ),
        ]
    }
}

final class BHHomePopularPlaceCell: UITableViewCell {

    static let reuseId = "BHHomePopularPlaceCell"

    var onTapDetail: (() -> Void)?

    /// 左上角封面图旁的举报入口；需提供 `UIButton` 以作 Sheet / popover anchor。
    var onThumbIssuesMenu: ((_ spot: BHPopularChinaSpot, _ sourceButton: UIButton) -> Void)?

    private var boundSpot: BHPopularChinaSpot?

    private let card = UIView()
    private let thumbImageView = UIImageView()

    private let thumbIssueBackdrop = UIView()
    private let thumbIssueButton = UIButton(type: .system)

    private let titleLabel = UILabel()
    private let certifiedBadge = UILabel()
    private let spacerView = UIView()
    private let detailButton = UIButton(type: .custom)
    private let locationLabel = UILabel()
    private let ratingPill = UILabel()
    private let strategyLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .white
        card.layer.cornerRadius = kScaleW(12)
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: kScaleW(2))
        card.layer.shadowRadius = kScaleW(6)
        card.layer.shadowOpacity = 1
        contentView.addSubview(card)

        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = kScaleW(10)
        thumbImageView.backgroundColor = .kHexColor(hexString: "#E8EAED")

        let issueSym = UIImage.SymbolConfiguration(pointSize: kScaleW(16), weight: .semibold)
        thumbIssueButton.setImage(
            UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: issueSym),
            for: .normal
        )
        thumbIssueButton.tintColor = UIColor.systemRed
        thumbIssueButton.adjustsImageWhenHighlighted = false
        thumbIssueButton.backgroundColor = .clear
        thumbIssueButton.accessibilityLabel = "举报或拉黑屏蔽"
        thumbIssueButton.addTarget(self, action: #selector(thumbIssuesTapped), for: .touchUpInside)

        thumbIssueBackdrop.backgroundColor = .white
        thumbIssueBackdrop.layer.cornerRadius = kScaleW(13)
        thumbIssueBackdrop.layer.masksToBounds = true

        titleLabel.font = .bh_pingFang(size: kScaleW(17), weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        certifiedBadge.font = .bh_pingFang(size: kScaleW(11), weight: .medium)
        certifiedBadge.textColor = .kHexColor(hexString: "#FF8A00")
        certifiedBadge.layer.borderColor = UIColor.kHexColor(hexString: "#FF8A00").cgColor
        certifiedBadge.layer.borderWidth = 1
        certifiedBadge.layer.cornerRadius = kScaleW(4)
        certifiedBadge.layer.masksToBounds = true
        certifiedBadge.textAlignment = .center
        certifiedBadge.setContentHuggingPriority(.required, for: .horizontal)
        certifiedBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        detailButton.setTitle("详情", for: .normal)
        detailButton.titleLabel?.font = .bh_pingFang(size: kScaleW(12), weight: .medium)
        detailButton.setTitleColor(.black, for: .normal)
        detailButton.backgroundColor = .kHexColor(hexString: "#C8FB5A")
        detailButton.layer.cornerRadius = kScaleW(14)
        detailButton.layer.masksToBounds = true
        detailButton.addTarget(self, action: #selector(detailPressed), for: .touchUpInside)
        detailButton.contentEdgeInsets = UIEdgeInsets(
            top: kScaleW(5),
            left: kScaleW(14),
            bottom: kScaleW(5),
            right: kScaleW(14)
        )

        let topRow = UIStackView(arrangedSubviews: [titleLabel, certifiedBadge, spacerView, detailButton])
        topRow.axis = .horizontal
        topRow.spacing = kScaleW(8)
        topRow.alignment = .center

        locationLabel.font = .bh_pingFang(size: kScaleW(12), weight: .regular)
        locationLabel.textColor = .kHexColor(hexString: "#888888")
        locationLabel.numberOfLines = 1

        ratingPill.font = .bh_pingFang(size: kScaleW(11), weight: .regular)
        ratingPill.textColor = .black
        ratingPill.backgroundColor = .kHexColor(hexString: "#A6F500")
        ratingPill.layer.cornerRadius = kScaleW(4)
        ratingPill.layer.masksToBounds = true
        ratingPill.textAlignment = .center
        ratingPill.setContentHuggingPriority(.required, for: .horizontal)
        ratingPill.setContentCompressionResistancePriority(.required, for: .horizontal)

        let ratingTrailingSpacer = UIView()
        ratingTrailingSpacer.translatesAutoresizingMaskIntoConstraints = false
        ratingTrailingSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let ratingRow = UIStackView(arrangedSubviews: [ratingPill, ratingTrailingSpacer])
        ratingRow.axis = .horizontal
        ratingRow.alignment = .center
        ratingRow.spacing = 0

        strategyLabel.font = .bh_pingFang(size: kScaleW(13), weight: .regular)
        strategyLabel.textColor = .black
        strategyLabel.numberOfLines = 2
        strategyLabel.lineBreakMode = .byTruncatingTail

        let textCol = UIStackView(arrangedSubviews: [topRow, locationLabel, ratingRow, strategyLabel])
        textCol.axis = .vertical
        textCol.spacing = kScaleW(8)
        textCol.alignment = .fill

        card.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbIssueBackdrop.translatesAutoresizingMaskIntoConstraints = false
        thumbIssueButton.translatesAutoresizingMaskIntoConstraints = false
        textCol.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(thumbImageView)
        card.addSubview(thumbIssueBackdrop)
        card.addSubview(thumbIssueButton)
        card.addSubview(textCol)

        let thumbW = kScaleW(114)
        let issueOuter = kScaleW(26)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: kScaleW(6)),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: kScaleW(14)),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(14)),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -kScaleW(6)),

            thumbImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: kScaleW(12)),
            thumbImageView.topAnchor.constraint(equalTo: card.topAnchor, constant: kScaleW(12)),
            thumbImageView.widthAnchor.constraint(equalToConstant: thumbW),
            thumbImageView.heightAnchor.constraint(equalTo: thumbImageView.widthAnchor),
            thumbImageView.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -kScaleW(12)),

            thumbIssueBackdrop.widthAnchor.constraint(equalToConstant: issueOuter),
            thumbIssueBackdrop.heightAnchor.constraint(equalToConstant: issueOuter),
            thumbIssueBackdrop.topAnchor.constraint(equalTo: thumbImageView.topAnchor, constant: kScaleW(6)),
            thumbIssueBackdrop.trailingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: -kScaleW(6)),

            thumbIssueButton.centerXAnchor.constraint(equalTo: thumbIssueBackdrop.centerXAnchor),
            thumbIssueButton.centerYAnchor.constraint(equalTo: thumbIssueBackdrop.centerYAnchor),
            thumbIssueButton.widthAnchor.constraint(equalToConstant: kScaleW(32)),
            thumbIssueButton.heightAnchor.constraint(equalToConstant: kScaleW(32)),

            textCol.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: kScaleW(12)),
            textCol.topAnchor.constraint(equalTo: card.topAnchor, constant: kScaleW(12)),
            textCol.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -kScaleW(12)),
            textCol.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -kScaleW(12)),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with spot: BHPopularChinaSpot) {
        boundSpot = spot
        titleLabel.text = spot.attractionTitle
        certifiedBadge.text = " 已认证 "
        locationLabel.text = spot.locationLine
        ratingPill.text = " 评分 \(spot.ratingDisplay) "
        strategyLabel.text = spot.strategyBrief
        thumbImageView.image =
            UIImage(named: spot.coverImageAssetName) ?? UIImage(named: "home_top_image")
        let hideIssues = spot.linkedFigureId == nil
        thumbIssueBackdrop.isHidden = hideIssues
        thumbIssueButton.isHidden = hideIssues
        thumbIssueButton.isEnabled = !hideIssues
        setNeedsLayout()
    }

    @objc private func thumbIssuesTapped() {
        guard let spot = boundSpot, spot.linkedFigureId != nil else { return }
        onThumbIssuesMenu?(spot, thumbIssueButton)
    }

    @objc private func detailPressed() {
        onTapDetail?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapDetail = nil
        onThumbIssuesMenu = nil
        boundSpot = nil
        thumbImageView.image = nil
        titleLabel.text = nil
        locationLabel.text = nil
        ratingPill.text = nil
        strategyLabel.text = nil
    }
}
