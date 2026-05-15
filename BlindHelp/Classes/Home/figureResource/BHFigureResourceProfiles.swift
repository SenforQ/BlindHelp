//
//  BHFigureResourceProfiles.swift
//  BlindHelp
//

import UIKit

/// `figureResource` 虚拟角色资料：头像资源名为 `man_{序号}_1`（与 bundle 内 PNG 一致）。
/// **朋友圈动态 `BHFigureMomentPost` 不包含头像字段**，其余文案、标签、配图占位等均完整给出。
/// 首页信息流 `home_travel_feed.json` 每条卡片可通过 **`figureId`（1…7）** 与本目录档案关联；参见 `BHHomeTravelFeedRoot.Item.figureId`。
struct BHFigureMomentPost {

    /// 列表展示昵称（与同档案 `nickname` 一致即可）
    let nickname: String

    let tag: String

    let body: String

    let imageAssetName: String?

    let showHotBadge: Bool
}

struct BHFigureNPCProfile {

    /// 档案序号 1…7，对应默认头像 `man_{id}_1`
    let figureId: Int

    /// 不含扩展名，用于 `UIImage(named:)`
    var defaultAvatarAssetName: String {
        "man_\(figureId)_1"
    }

    /// 2～4 字网名
    let nickname: String

    /// 自「旅行、徒步、运动、看书、音乐」择一（与 `BHUserProfileManager.hobbyTitles` 对齐）
    let hobby: String

    /// 与编辑资料一致的性格摘要（便于写入本地资料模型）
    let personality: String

    /// 「省 + 空格 + 市」
    let regionProvinceCity: String

    /// 阳光正向签名
    let signature: String

    /// 朋友圈动态（无头像字段）
    let moments: [BHFigureMomentPost]

    func hobbyIndexMatchingProfileStore() -> Int {
        BHUserProfileManager.hobbyTitles.firstIndex(of: hobby) ?? 0
    }

    func loadAvatarImage() -> UIImage? {
        if let img = UIImage(named: defaultAvatarAssetName) {
            return img
        }
        return UIImage(named: "applogo")
    }

    /// `man_*_2` 起依次为相册图；取 **序号最大的已存在资源** 作顶部背景；否则用头像。
    func loadLastAlbumPhotoOrAvatarFallback() -> UIImage? {
        if let last = loadGalleryPhotosExcludingAvatar().last {
            return last
        }
        return loadAvatarImage()
    }

    /// 相册图：`man_{figureId}_2` … 直到 `UIImage(named:)` 不可用为止；不含 `man_{figureId}_1`（用作头像）。
    func loadGalleryPhotosExcludingAvatar(maxSuffix: Int = 12) -> [UIImage] {
        var out: [UIImage] = []
        for y in 2 ... maxSuffix {
            let asset = "man_\(figureId)_\(y)"
            guard let img = UIImage(named: asset) else {
                continue
            }
            out.append(img)
        }
        return out
    }
}

/// `figureResource` 内置 NPC；头像默认为各目录 `man_x_1`。
enum BHFigureResourceCatalog {

    static let hobbyPool = BHUserProfileManager.hobbyTitles

    static let allProfiles: [BHFigureNPCProfile] = [
        BHFigureNPCProfile(
            figureId: 1,
            nickname: "沐光",
            hobby: "徒步",
            personality: "开朗",
            regionProvinceCity: "云南省 丽江市",
            signature: "趁晨光上路，每一步都算数；心里有阳光，泥泞也是风景。",
            moments: [
                BHFigureMomentPost(
                    nickname: "沐光",
                    tag: "徒步",
                    body: "玉龙雪山脚下吹风，告诉自己：慢一点也没关系，只要在向前走。",
                    imageAssetName: "man_1_2",
                    showHotBadge: true
                ),
                BHFigureMomentPost(
                    nickname: "沐光",
                    tag: "日常",
                    body: "古城石板路走走停停，一杯酥油茶暖胃也暖心～",
                    imageAssetName: "man_1_3",
                    showHotBadge: false
                ),
            ]
        ),
        BHFigureNPCProfile(
            figureId: 2,
            nickname: "阿辰",
            hobby: "旅行",
            personality: "随性",
            regionProvinceCity: "四川省 成都市",
            signature: "世界很大，我先从家门口的小吃街爱到远方的山海。",
            moments: [
                BHFigureMomentPost(
                    nickname: "阿辰",
                    tag: "旅行",
                    body: "宽窄巷子人潮里听见笑声，才发现热闹也是一种温柔治愈。",
                    imageAssetName: "man_2_2",
                    showHotBadge: false
                ),
                BHFigureMomentPost(
                    nickname: "阿辰",
                    tag: "美食",
                    body: "麻辣鲜香提醒我今天也要对生活多一点热爱呀！",
                    imageAssetName: "man_2_3",
                    showHotBadge: true
                ),
            ]
        ),
        BHFigureNPCProfile(
            figureId: 3,
            nickname: "初夏",
            hobby: "音乐",
            personality: "细腻",
            regionProvinceCity: "江苏省 苏州市",
            signature: "耳机里的旋律和窗外的绿意，都是我珍藏的好天气。",
            moments: [
                BHFigureMomentPost(
                    nickname: "初夏",
                    tag: "音乐",
                    body: "平江路坐船听雨，单曲循环一整下午也不腻。",
                    imageAssetName: "man_3_2",
                    showHotBadge: false
                ),
                BHFigureMomentPost(
                    nickname: "初夏",
                    tag: "园林",
                    body: "留园一角光影斑驳，忽然懂了什么叫岁月静好。",
                    imageAssetName: "man_3_3",
                    showHotBadge: true
                ),
            ]
        ),
        BHFigureNPCProfile(
            figureId: 4,
            nickname: "远山",
            hobby: "看书",
            personality: "沉静",
            regionProvinceCity: "陕西省 西安市",
            signature: "翻开一页书，也像推开一扇通往远方的窗。",
            moments: [
                BHFigureMomentPost(
                    nickname: "远山",
                    tag: "书香",
                    body: "城墙根下的咖啡馆读到日落，字里行间的长安依旧滚烫。",
                    imageAssetName: "man_4_2",
                    showHotBadge: false
                ),
                BHFigureMomentPost(
                    nickname: "远山",
                    tag: "漫步",
                    body: "回民街的烟火气提醒我：认真吃饭也是认真生活。",
                    imageAssetName: "man_4_3",
                    showHotBadge: false
                ),
            ]
        ),
        BHFigureNPCProfile(
            figureId: 5,
            nickname: "晴空",
            hobby: "运动",
            personality: "利落",
            regionProvinceCity: "广东省 深圳市",
            signature: "流汗的快乐最真实，元气满满就是最好的滤镜。",
            moments: [
                BHFigureMomentPost(
                    nickname: "晴空",
                    tag: "跑步",
                    body: "滨海长廊晨跑五公里，海风把疲惫全部吹跑啦！",
                    imageAssetName: "man_5_2",
                    showHotBadge: true
                ),
                BHFigureMomentPost(
                    nickname: "晴空",
                    tag: "骑行",
                    body: "红绿灯间隙也想对自己说：加油，你真的超棒的。",
                    imageAssetName: "man_5_3",
                    showHotBadge: false
                ),
            ]
        ),
        BHFigureNPCProfile(
            figureId: 6,
            nickname: "小鹿",
            hobby: "旅行",
            personality: "温柔",
            regionProvinceCity: "浙江省 杭州市",
            signature: "西湖的风吹在脸上，提醒我温柔地对待自己和世界。",
            moments: [
                BHFigureMomentPost(
                    nickname: "小鹿",
                    tag: "湖畔",
                    body: "断桥边晒太阳发呆，把时间浪费在美好的事物上不算浪费。",
                    imageAssetName: "man_6_2",
                    showHotBadge: false
                ),
                BHFigureMomentPost(
                    nickname: "小鹿",
                    tag: "茶香",
                    body: "龙井村里一壶春茶，和同学聊起明年的远行计划。",
                    imageAssetName: "man_6_3",
                    showHotBadge: true
                ),
            ]
        ),
        BHFigureNPCProfile(
            figureId: 7,
            nickname: "知行客",
            hobby: "徒步",
            personality: "稳重",
            regionProvinceCity: "山东省 青岛市",
            signature: "海风咸涩却清澈，像我执意奔赴山海的那份倔强与欢喜。",
            moments: [
                BHFigureMomentPost(
                    nickname: "知行客",
                    tag: "海边",
                    body: "八大关林荫路和蔚蓝海岸线同框，脚步慢一点也没关系。",
                    imageAssetName: "man_7_2",
                    showHotBadge: false
                ),
                BHFigureMomentPost(
                    nickname: "知行客",
                    tag: "爬山",
                    body: "崂山雾散那一刻，真想对所有烦恼说声后会无期。",
                    imageAssetName: "man_7_3",
                    showHotBadge: true
                ),
            ]
        ),
    ]

    /// 按编号取档案；超出范围返回 `nil`。
    static func profile(figureId: Int) -> BHFigureNPCProfile? {
        allProfiles.first { $0.figureId == figureId }
    }
}

enum BHFigureMomentLikeStore {

    private static let storageKey = "BHFigureMomentLikedMomentKeys.v1"

    static func stableKey(figureId: Int, imageAssetName: String?) -> String {
        "\(figureId)|\(imageAssetName ?? "")"
    }

    private static func loadSet() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? [])
    }

    private static func saveSet(_ keys: Set<String>) {
        UserDefaults.standard.set(Array(keys), forKey: storageKey)
    }

    static func isLiked(figureId: Int, imageAssetName: String?) -> Bool {
        loadSet().contains(stableKey(figureId: figureId, imageAssetName: imageAssetName))
    }

    static func setLiked(_ liked: Bool, figureId: Int, imageAssetName: String?) {
        let k = stableKey(figureId: figureId, imageAssetName: imageAssetName)
        var keys = loadSet()
        if liked {
            keys.insert(k)
        } else {
            keys.remove(k)
        }
        saveSet(keys)
    }

    static func toggle(figureId: Int, imageAssetName: String?) {
        setLiked(!isLiked(figureId: figureId, imageAssetName: imageAssetName), figureId: figureId, imageAssetName: imageAssetName)
    }
}
