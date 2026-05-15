//
//  BHMovieResourceCatalog.swift
//  BlindHelp
//

import AVFoundation
import UIKit

struct BHMovieResourceItem {

    let figureId: Int

    var resourceStem: String {
        "man_video_\(figureId)_1"
    }

    func bundleVideoURL() -> URL? {
        if let url = Bundle.main.url(forResource: resourceStem, withExtension: "mp4", subdirectory: "movieResource") {
            return url
        }
        return Bundle.main.url(forResource: resourceStem, withExtension: "mp4")
    }
}

enum BHMovieResourceCatalog {

    static let bundledFigureIdsOrdered: [Int] = [1, 2, 3, 4, 5, 6]

    static var items: [BHMovieResourceItem] {
        bundledFigureIdsOrdered.map { BHMovieResourceItem(figureId: $0) }
    }

    /// 与 `bundledFigureIdsOrdered` 一致的首页可用视频：**正序**，已剔除拉黑／屏蔽条目。
    static var homeFeedVisibleItemsForwardOrder: [BHMovieResourceItem] {
        items.filter { !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: $0.figureId) }
    }

    /// 首页「旅行视频」头部三张精选：**正序**读取下的前三条可见视频。
    static var homeFeedHeaderHeroMovies: [BHMovieResourceItem] {
        Array(homeFeedVisibleItemsForwardOrder.prefix(3))
    }

    /// 首页「旅行视频」「猜你喜欢」网格：在正序列表上 **倒序** 展示。
    static var homeFeedVisibleItems: [BHMovieResourceItem] {
        Array(homeFeedVisibleItemsForwardOrder.reversed())
    }
}

enum BHMovieThumbnailCache {

    private static let workQueue = DispatchQueue(label: "com.blindhelp.movie.thumbnail", qos: .utility)
    private static let cache = NSCache<NSString, UIImage>()

    static func thumbnail(for item: BHMovieResourceItem, completion: @escaping (UIImage?) -> Void) {
        let key = item.resourceStem as NSString
        if let hit = cache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(hit)
            }
            return
        }
        workQueue.async {
            var out: UIImage?
            defer {
                if let img = out {
                    cache.setObject(img, forKey: key)
                }
                DispatchQueue.main.async {
                    completion(out)
                }
            }
            guard let url = item.bundleVideoURL() else { return }
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 720, height: 1280)
            let time = CMTime(seconds: 0.6, preferredTimescale: 600)
            do {
                let cg = try gen.copyCGImage(at: time, actualTime: nil)
                out = UIImage(cgImage: cg)
            } catch {
                out = nil
            }
        }
    }
}

enum BHHomeMovieVideoReuse {

    static let videoCell = "BHHomeTravelVideoGridCell"
}

final class BHHomeTravelVideoGridCell: UICollectionViewCell {

    private let previewImageView = UIImageView()
    private let dimLayer = UIView()
    private let playGlyphView = UIImageView()
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private var loadToken = UUID()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = kScaleW(12)

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        contentView.addSubview(previewImageView)

        dimLayer.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        contentView.addSubview(dimLayer)

        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        playGlyphView.image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        playGlyphView.tintColor = UIColor.white.withAlphaComponent(0.92)
        playGlyphView.contentMode = .scaleAspectFit
        contentView.addSubview(playGlyphView)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        contentView.addSubview(avatarImageView)

        titleLabel.font = .bh_pingFang(size: 13, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadToken = UUID()
        previewImageView.image = nil
        avatarImageView.image = nil
        titleLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewImageView.frame = contentView.bounds
        dimLayer.frame = contentView.bounds
        let side = kScaleW(44)
        playGlyphView.frame = CGRect(
            x: (contentView.bounds.width - side) * 0.5,
            y: (contentView.bounds.height - side) * 0.5 - kScaleW(12),
            width: side,
            height: side
        )
        let pad = kScaleW(10)
        let titleStripH = kScaleW(40)
        let avatarSide = kScaleW(26)
        let stripTop = contentView.bounds.height - pad - titleStripH

        avatarImageView.frame = CGRect(
            x: pad,
            y: stripTop + (titleStripH - avatarSide) * 0.5,
            width: avatarSide,
            height: avatarSide
        )
        avatarImageView.layer.cornerRadius = avatarSide / 2

        let nicknameGap = kScaleW(6)
        titleLabel.frame = CGRect(
            x: pad + avatarSide + nicknameGap,
            y: stripTop,
            width: contentView.bounds.width - pad * 2 - avatarSide - nicknameGap,
            height: titleStripH
        )
    }

    func apply(item: BHMovieResourceItem, displayTitle: String) {
        titleLabel.text = displayTitle
        avatarImageView.image =
            BHFigureResourceCatalog.profile(figureId: item.figureId)?.loadAvatarImage()
            ?? UIImage(named: "applogo")

        let token = UUID()
        loadToken = token
        let placeholder = UIImage(named: "home_top_image")
        previewImageView.image = placeholder
        BHMovieThumbnailCache.thumbnail(for: item) { [weak self] img in
            guard let self else { return }
            guard self.loadToken == token else { return }
            self.previewImageView.image = img ?? placeholder
        }
        setNeedsLayout()
    }
}
