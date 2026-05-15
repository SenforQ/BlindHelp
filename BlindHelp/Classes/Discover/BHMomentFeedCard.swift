//
//  BHMomentFeedCard.swift
//  BlindHelp
//

import UIKit

/// 首页 / 广场 / 话题详情共用的 NPC 朋友圈卡片数据源。
struct BHMomentFeedCardModel {

    let figureId: Int

    let profile: BHFigureNPCProfile

    let post: BHFigureMomentPost
}

/// 头像 + 昵称 + 时间 + … + 点赞 + 正文 + 正方形配图。
final class BHMomentFeedCardView: UIView {

    var figureIdBinding: Int = 0

    private let avatarImageView = UIImageView()
    private let nameRowStack = UIStackView()
    private let nameLabel = UILabel()
    private let vipBadgeIcon = UIImageView()
    private let timeLabel = UILabel()
    private let moreMenuButton = UIButton(type: .system)
    private let likeThumbButton = UIButton(type: .system)
    private let bodyLabel = UILabel()

    private let topicTagCueLabel = UILabel()

    private let momentImageView = UIImageView()

    private var boundPostAssetName: String?
    private let likeSymbolCfg = UIImage.SymbolConfiguration(pointSize: kScaleW(17), weight: .medium)

    var onMomentLikeRefresh: (() -> Void)?
    var onMomentMoreActions: ((_ sourceButton: UIButton, _ figureId: Int, _ nickname: String) -> Void)?
    var onMomentAvatarTap: ((_ figureId: Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = kScaleW(14)
        layer.masksToBounds = false
        backgroundColor = UIColor.white
        layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        layer.shadowOffset = CGSize(width: 0, height: kScaleW(3))
        layer.shadowOpacity = 1
        layer.shadowRadius = kScaleW(8)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = kScaleW(20)
        avatarImageView.isUserInteractionEnabled = true

        let avTap = UITapGestureRecognizer(target: self, action: #selector(avatarGestureTapped))
        avatarImageView.addGestureRecognizer(avTap)

        nameLabel.font = .bh_pingFang(size: kScaleW(15), weight: .medium)
        nameLabel.textColor = .black

        vipBadgeIcon.image =
            UIImage(
                systemName: "diamond.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: kScaleW(13), weight: .semibold)
            )
        vipBadgeIcon.tintColor = UIColor.kHexColor(hexString: "#FF9500")
        vipBadgeIcon.contentMode = .scaleAspectFit
        vipBadgeIcon.setContentHuggingPriority(.required, for: .horizontal)
        vipBadgeIcon.setContentCompressionResistancePriority(.required, for: .horizontal)

        nameRowStack.axis = .horizontal
        nameRowStack.spacing = kScaleW(4)
        nameRowStack.alignment = .center
        nameRowStack.addArrangedSubview(nameLabel)
        nameRowStack.addArrangedSubview(vipBadgeIcon)

        timeLabel.font = .bh_pingFang(size: kScaleW(12), weight: .regular)
        timeLabel.textColor = UIColor.kHexColor(hexString: "#979797")

        let nameCol = UIStackView(arrangedSubviews: [nameRowStack, timeLabel])
        nameCol.axis = .vertical
        nameCol.spacing = kScaleW(2)
        nameCol.setContentCompressionResistancePriority(.required, for: .vertical)

        let moreCfg = UIImage.SymbolConfiguration(pointSize: kScaleW(17), weight: .medium)
        moreMenuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: moreCfg), for: .normal)
        moreMenuButton.tintColor = UIColor.kHexColor(hexString: "#AAAAAA")
        moreMenuButton.accessibilityLabel = "举报或拉黑屏蔽"
        moreMenuButton.addTarget(self, action: #selector(morePressed), for: .touchUpInside)

        likeThumbButton.setImage(
            UIImage(systemName: "hand.thumbsup", withConfiguration: likeSymbolCfg),
            for: .normal
        )
        likeThumbButton.tintColor = UIColor.kHexColor(hexString: "#979797")
        likeThumbButton.addTarget(self, action: #selector(likePressed), for: .touchUpInside)

        let rightHud = UIStackView(arrangedSubviews: [moreMenuButton, likeThumbButton])
        rightHud.axis = .horizontal
        rightHud.spacing = kScaleW(6)
        rightHud.alignment = .center

        let topMiddle = UIView()
        topMiddle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let topRowOuter = UIView()
        [avatarImageView, nameCol, topMiddle, rightHud].forEach {
            topRowOuter.addSubview($0)
        }
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nameCol.translatesAutoresizingMaskIntoConstraints = false
        topMiddle.translatesAutoresizingMaskIntoConstraints = false
        rightHud.translatesAutoresizingMaskIntoConstraints = false
        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
        likeThumbButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: topRowOuter.leadingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: topRowOuter.topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: kScaleW(40)),
            avatarImageView.heightAnchor.constraint(equalToConstant: kScaleW(40)),
            avatarImageView.bottomAnchor.constraint(equalTo: topRowOuter.bottomAnchor),

            nameCol.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: kScaleW(10)),
            nameCol.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),

            topMiddle.leadingAnchor.constraint(equalTo: nameCol.trailingAnchor),
            topMiddle.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            topMiddle.widthAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(4)),

            rightHud.leadingAnchor.constraint(equalTo: topMiddle.trailingAnchor),
            rightHud.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            rightHud.trailingAnchor.constraint(equalTo: topRowOuter.trailingAnchor),

            moreMenuButton.widthAnchor.constraint(equalToConstant: kScaleW(40)),
            moreMenuButton.heightAnchor.constraint(equalToConstant: kScaleW(34)),
            likeThumbButton.heightAnchor.constraint(equalToConstant: kScaleW(34)),
            likeThumbButton.widthAnchor.constraint(equalToConstant: kScaleW(42)),
        ])

        bodyLabel.font = .bh_pingFang(size: kScaleW(14), weight: .regular)
        bodyLabel.textColor = .black
        bodyLabel.numberOfLines = 0

        topicTagCueLabel.font = .bh_pingFang(size: kScaleW(13), weight: .medium)
        topicTagCueLabel.textColor = UIColor.kHexColor(hexString: "#EE6B41")

        momentImageView.contentMode = .scaleAspectFill
        momentImageView.layer.cornerRadius = kScaleW(8)
        momentImageView.clipsToBounds = true
        momentImageView.backgroundColor = UIColor.kHexColor(hexString: "#EEF0F3")

        let stack = UIStackView(arrangedSubviews: [topRowOuter, topicTagCueLabel, bodyLabel, momentImageView])
        stack.axis = .vertical
        stack.spacing = kScaleW(10)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: kScaleW(14)),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kScaleW(14)),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -kScaleW(14)),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -kScaleW(14)),

            momentImageView.heightAnchor.constraint(equalTo: momentImageView.widthAnchor),
        ])

        vipBadgeIcon.isHidden = false
        topRowOuter.translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func avatarGestureTapped() {
        guard figureIdBinding != 0 else { return }
        onMomentAvatarTap?(figureIdBinding)
    }

    @objc private func morePressed() {
        onMomentMoreActions?(moreMenuButton, figureIdBinding, nameLabel.text ?? "旅友")
    }

    @objc private func likePressed() {
        BHFigureMomentLikeStore.toggle(
            figureId: figureIdBinding,
            imageAssetName: boundPostAssetName
        )
        refreshLikeAppearance()
        onMomentLikeRefresh?()
    }

    private func refreshLikeAppearance() {
        let liked =
            BHFigureMomentLikeStore.isLiked(
                figureId: figureIdBinding,
                imageAssetName: boundPostAssetName
            )
        let sym = liked ? "hand.thumbsup.fill" : "hand.thumbsup"
        likeThumbButton.setImage(UIImage(systemName: sym, withConfiguration: likeSymbolCfg), for: .normal)
        likeThumbButton.tintColor =
            liked
            ? UIColor.kHexColor(hexString: "#A6F500")
            : UIColor.kHexColor(hexString: "#979797")
    }

    func configure(model: BHMomentFeedCardModel) {
        figureIdBinding = model.figureId
        boundPostAssetName = model.post.imageAssetName

        avatarImageView.image = model.profile.loadAvatarImage()
        nameLabel.text = model.post.nickname
        timeLabel.text = "1小时前"
        bodyLabel.text = model.post.body

        let trimmedTag = model.post.tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTag.isEmpty {
            topicTagCueLabel.text = nil
            topicTagCueLabel.isHidden = true
        } else {
            topicTagCueLabel.isHidden = false
            topicTagCueLabel.text = "#\(trimmedTag)"
        }

        let asset = model.post.imageAssetName ?? "man_\(model.figureId)_2"
        momentImageView.image =
            UIImage(named: asset) ?? model.profile.loadLastAlbumPhotoOrAvatarFallback()

        vipBadgeIcon.isHidden = !model.post.showHotBadge
        refreshLikeAppearance()
    }
}

final class BHFigureFeedHideObserverToken {

    private let ncToken: NSObjectProtocol

    init(onMainFire: @escaping () -> Void) {
        ncToken = NotificationCenter.default.addObserver(
            forName: .bhHomeFigureBlockedOrShieldedListDidChange,
            object: nil,
            queue: .main,
            using: { _ in
                onMainFire()
            }
        )
    }

    @MainActor deinit {
        NotificationCenter.default.removeObserver(ncToken)
    }
}
