//
//  BHDetailFigureViewController.swift
//  BlindHelp
//

import UIKit

/// 图文角色主页（资料 / 动态），顶部头图与关注状态与本地 `BHVideoFigureFollowStore` 同步。
final class BHDetailFigureViewController: BHBaseViewController {

    private let figureId: Int

    private var npc: BHFigureNPCProfile?

    private let heroImageView = UIImageView()
    private let topFloatingBar = UIView()
    private let backFloatingButton = UIButton(type: .system)
    private let expandFloatingButton = UIButton(type: .system)
    private let messageFloatingButton = UIButton(type: .custom)
    private let topRightFloatingStack = UIStackView()

    private let cardShell = UIView()
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let followButton = UIButton(type: .system)
    private let headerTrailingStack = UIStackView()
    private let headerMoreCapsuleButton = UIButton(type: .system)

    private let tabInfoButton = UIButton(type: .system)
    private let tabFeedButton = UIButton(type: .system)
    private let tabUnderlineView = UIView()

    private let infoScrollView = UIScrollView()
    private let infoStackView = UIStackView()
    private let feedTableView = UITableView(frame: .zero, style: .plain)

    private var selectedTab: Int = 0

    init(figureId: Int) {
        self.figureId = figureId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        baseBackgroundTopImgV.isHidden = true
        baseBackgroundBodyImgV.isHidden = true
        view.backgroundColor = .white
        kdNavBar.isHidden = true
        npc = BHFigureResourceCatalog.profile(figureId: figureId)
        navigationItem.title = ""

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.image =
            npc?.loadLastAlbumPhotoOrAvatarFallback() ?? UIImage(named: "home_top_image")

        let backCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        backFloatingButton.setImage(
            UIImage(systemName: "chevron.left", withConfiguration: backCfg),
            for: .normal
        )
        backFloatingButton.tintColor = .white
        backFloatingButton.addTarget(self, action: #selector(floatingBackTapped), for: .touchUpInside)
        backFloatingButton.adjustsImageWhenHighlighted = false
        let expandCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        expandFloatingButton.setImage(
            UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: expandCfg),
            for: .normal
        )
        expandFloatingButton.tintColor = .white
        expandFloatingButton.isHidden = true
        expandFloatingButton.adjustsImageWhenHighlighted = false
        expandFloatingButton.addTarget(self, action: #selector(expandPreviewTapped), for: .touchUpInside)

        let msgCfg = UIImage.SymbolConfiguration(pointSize: kScaleW(17), weight: .medium)
        messageFloatingButton.setImage(
            UIImage(systemName: "message.fill", withConfiguration: msgCfg),
            for: .normal
        )
        messageFloatingButton.tintColor = .black
        messageFloatingButton.backgroundColor = .white
        messageFloatingButton.layer.cornerRadius = kScaleW(22)
        messageFloatingButton.clipsToBounds = true
        messageFloatingButton.adjustsImageWhenHighlighted = false
        messageFloatingButton.addTarget(self, action: #selector(messageFloatingTapped), for: .touchUpInside)
        messageFloatingButton.accessibilityLabel = "私信"

        topRightFloatingStack.axis = .horizontal
        topRightFloatingStack.spacing = kScaleW(8)
        topRightFloatingStack.alignment = .center
        topRightFloatingStack.distribution = .fill
        topRightFloatingStack.addArrangedSubview(expandFloatingButton)
        topRightFloatingStack.addArrangedSubview(messageFloatingButton)

        topFloatingBar.backgroundColor = .clear
        view.addSubview(heroImageView)
        view.addSubview(cardShell)
        view.addSubview(topFloatingBar)
        topFloatingBar.addSubview(backFloatingButton)
        topFloatingBar.addSubview(topRightFloatingStack)

        cardShell.backgroundColor = .white
        cardShell.layer.cornerRadius = kScaleW(18)
        cardShell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardShell.layer.masksToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        if let npc {
            avatarImageView.image = npc.loadAvatarImage()
            titleLabel.text = npc.nickname
        } else {
            avatarImageView.image = UIImage(named: "applogo")
            titleLabel.text = "旅友"
        }

        titleLabel.font = .bh_pingFang(size: kScaleW(19), weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        configureFollowHighlightHandlers()
        refreshFollowAppearance()

        headerTrailingStack.axis = .horizontal
        headerTrailingStack.alignment = .center
        headerTrailingStack.spacing = kScaleW(8)
        headerTrailingStack.distribution = .fill
        configureHeaderBlackCapsule(headerMoreCapsuleButton, title: "更多")
        headerMoreCapsuleButton.addTarget(self, action: #selector(headerMoreCapsuleTapped), for: .touchUpInside)
        headerTrailingStack.addArrangedSubview(followButton)
        headerTrailingStack.addArrangedSubview(headerMoreCapsuleButton)
        followButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        tabInfoButton.setTitle("资料", for: .normal)
        tabFeedButton.setTitle("动态", for: .normal)
        tabInfoButton.addTarget(self, action: #selector(tabInfoTapped), for: .touchUpInside)
        tabFeedButton.addTarget(self, action: #selector(tabFeedTapped), for: .touchUpInside)
        tabUnderlineView.backgroundColor = .kHexColor(hexString: "#A6F500")

        tabInfoButton.tag = 0
        tabFeedButton.tag = 1

        infoScrollView.alwaysBounceVertical = true
        infoScrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            infoScrollView.contentInsetAdjustmentBehavior = .never
        }

        infoStackView.axis = .vertical
        infoStackView.spacing = kScaleW(16)
        infoStackView.alignment = .fill

        populateInfoSections()

        feedTableView.separatorStyle = .none
        feedTableView.backgroundColor = .white
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.register(BHDetailMomentPostCell.self, forCellReuseIdentifier: BHDetailMomentPostCell.reuseId)
        if #available(iOS 11.0, *) {
            feedTableView.contentInsetAdjustmentBehavior = .never
        }

        cardShell.addSubview(avatarImageView)
        cardShell.addSubview(titleLabel)
        cardShell.addSubview(headerTrailingStack)
        cardShell.addSubview(tabInfoButton)
        cardShell.addSubview(tabFeedButton)
        cardShell.addSubview(tabUnderlineView)
        cardShell.addSubview(infoScrollView)
        cardShell.addSubview(feedTableView)

        infoScrollView.addSubview(infoStackView)

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        cardShell.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerTrailingStack.translatesAutoresizingMaskIntoConstraints = false
        followButton.translatesAutoresizingMaskIntoConstraints = false
        headerMoreCapsuleButton.translatesAutoresizingMaskIntoConstraints = false
        tabInfoButton.translatesAutoresizingMaskIntoConstraints = false
        tabFeedButton.translatesAutoresizingMaskIntoConstraints = false
        tabUnderlineView.translatesAutoresizingMaskIntoConstraints = true
        infoScrollView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        feedTableView.translatesAutoresizingMaskIntoConstraints = false
        topFloatingBar.translatesAutoresizingMaskIntoConstraints = false
        backFloatingButton.translatesAutoresizingMaskIntoConstraints = false
        expandFloatingButton.translatesAutoresizingMaskIntoConstraints = false
        messageFloatingButton.translatesAutoresizingMaskIntoConstraints = false
        topRightFloatingStack.translatesAutoresizingMaskIntoConstraints = false

        let avatarSide = kScaleW(82)
        let heroH = kScaleW(268)
        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: view.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: heroH),

            cardShell.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardShell.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardShell.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -kScaleW(46)),
            cardShell.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            topFloatingBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: kScaleW(4)),
            topFloatingBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: kScaleW(8)),
            topFloatingBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -kScaleW(8)),
            topFloatingBar.heightAnchor.constraint(equalToConstant: kScaleW(44)),

            backFloatingButton.leadingAnchor.constraint(equalTo: topFloatingBar.leadingAnchor),
            backFloatingButton.centerYAnchor.constraint(equalTo: topFloatingBar.centerYAnchor),
            backFloatingButton.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            backFloatingButton.heightAnchor.constraint(equalToConstant: kScaleW(44)),

            topRightFloatingStack.trailingAnchor.constraint(equalTo: topFloatingBar.trailingAnchor),
            topRightFloatingStack.centerYAnchor.constraint(equalTo: topFloatingBar.centerYAnchor),

            expandFloatingButton.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            expandFloatingButton.heightAnchor.constraint(equalToConstant: kScaleW(44)),
            messageFloatingButton.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            messageFloatingButton.heightAnchor.constraint(equalToConstant: kScaleW(44)),

            avatarImageView.leadingAnchor.constraint(equalTo: cardShell.leadingAnchor, constant: kScaleW(18)),
            avatarImageView.topAnchor.constraint(equalTo: cardShell.topAnchor, constant: kScaleW(18)),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSide),
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSide),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: kScaleW(12)),
            titleLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerTrailingStack.leadingAnchor, constant: -kScaleW(8)),

            headerTrailingStack.trailingAnchor.constraint(equalTo: cardShell.trailingAnchor, constant: -kScaleW(14)),
            headerTrailingStack.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            headerTrailingStack.heightAnchor.constraint(lessThanOrEqualToConstant: avatarSide),

            followButton.widthAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(84)),
            followButton.heightAnchor.constraint(equalToConstant: kScaleW(38)),
            headerMoreCapsuleButton.heightAnchor.constraint(equalToConstant: kScaleW(38)),
            headerMoreCapsuleButton.widthAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(64)),

            tabInfoButton.leadingAnchor.constraint(equalTo: cardShell.leadingAnchor, constant: kScaleW(16)),
            tabInfoButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: kScaleW(20)),
            tabInfoButton.heightAnchor.constraint(equalToConstant: kScaleW(34)),

            tabFeedButton.leadingAnchor.constraint(equalTo: tabInfoButton.trailingAnchor, constant: kScaleW(28)),
            tabFeedButton.centerYAnchor.constraint(equalTo: tabInfoButton.centerYAnchor),
            tabFeedButton.heightAnchor.constraint(equalToConstant: kScaleW(34)),

            infoScrollView.leadingAnchor.constraint(equalTo: cardShell.leadingAnchor),
            infoScrollView.trailingAnchor.constraint(equalTo: cardShell.trailingAnchor),
            infoScrollView.topAnchor.constraint(equalTo: tabInfoButton.bottomAnchor, constant: kScaleW(12)),
            infoScrollView.bottomAnchor.constraint(equalTo: cardShell.bottomAnchor),

            feedTableView.leadingAnchor.constraint(equalTo: cardShell.leadingAnchor),
            feedTableView.trailingAnchor.constraint(equalTo: cardShell.trailingAnchor),
            feedTableView.topAnchor.constraint(equalTo: tabInfoButton.bottomAnchor, constant: kScaleW(12)),
            feedTableView.bottomAnchor.constraint(equalTo: cardShell.bottomAnchor),

            infoStackView.topAnchor.constraint(equalTo: infoScrollView.contentLayoutGuide.topAnchor, constant: kScaleW(4)),
            infoStackView.leadingAnchor.constraint(equalTo: infoScrollView.contentLayoutGuide.leadingAnchor, constant: kScaleW(14)),
            infoStackView.trailingAnchor.constraint(equalTo: infoScrollView.contentLayoutGuide.trailingAnchor, constant: -kScaleW(14)),
            infoStackView.bottomAnchor.constraint(equalTo: infoScrollView.contentLayoutGuide.bottomAnchor, constant: -kScaleW(28)),
            infoStackView.widthAnchor.constraint(equalTo: infoScrollView.frameLayoutGuide.widthAnchor, constant: -kScaleW(28)),
        ])

        view.bringSubviewToFront(topFloatingBar)
        avatarImageView.layer.cornerRadius = avatarSide / 2

        feedTableView.reloadData()
        reloadTabUnderline(animated: false)

        UIView.performWithoutAnimation {
            self.followButton.transform = .identity
        }
    }

    override func setupBodyView() {}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTabUnderlineFrames()
    }

    private func configureHeaderBlackCapsule(_ button: UIButton, title: String) {
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.baseForegroundColor = .white
        cfg.baseBackgroundColor = .black
        cfg.cornerStyle = .capsule
        cfg.buttonSize = .small
        cfg.contentInsets = NSDirectionalEdgeInsets(
            top: kScaleW(6),
            leading: kScaleW(12),
            bottom: kScaleW(6),
            trailing: kScaleW(12)
        )
        let font = UIFont.bh_pingFang(size: kScaleW(13), weight: .medium)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var o = incoming
            o.font = font
            return o
        }
        button.configuration = cfg
        button.adjustsImageWhenHighlighted = false
    }

    @objc private func headerMoreCapsuleTapped() {
        presentFigureMoreActionsActionSheet(from: headerMoreCapsuleButton)
    }

    private func presentFigureMoreActionsActionSheet(from sourceView: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "举报", style: .default) { [weak self] _ in
            self?.openFigureReportPage()
        })
        sheet.addAction(UIAlertAction(title: "拉黑", style: .destructive) { [weak self] _ in
            self?.applyBlockFromMoreMenu()
        })
        sheet.addAction(UIAlertAction(title: "屏蔽", style: .destructive) { [weak self] _ in
            self?.applyShieldFromMoreMenu()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(sheet, animated: true)
    }

    private func openFigureReportPage() {
        let name = npc?.nickname ?? "旅友"
        let report = BHFigureReportViewController(figureId: figureId, targetDisplayName: name)
        bh_dismissFullscreenPresentedHostingStackThenPerform { [weak self] in
            guard let self else { return }
            let tabBar = BHBaseTabBarControllerManager.shared.tabBarController
            tabBar.selectedIndex = 0
            guard let homeNav = tabBar.viewControllers?.first as? UINavigationController else {
                self.view.cd_showDefaultToast("无法打开举报页")
                return
            }
            homeNav.popToRootViewController(animated: false)
            homeNav.pushViewController(report, animated: true)
        }
    }

    private func bh_dismissFullscreenPresentedHostingStackThenPerform(completion: @escaping () -> Void) {
        func finishAfterClearingHostedPresentees(from vc: UIViewController?, thenDisownNavCompletion: @escaping () -> Void) {
            guard let v = vc else {
                completion()
                return
            }
            if let layered = v.presentedViewController {
                layered.dismiss(animated: false) {
                    finishAfterClearingHostedPresentees(from: v, thenDisownNavCompletion: thenDisownNavCompletion)
                }
                return
            }
            guard let enclosingNav = v.navigationController ?? (v as? UINavigationController) else {
                thenDisownNavCompletion()
                return
            }
            if enclosingNav.presentingViewController != nil {
                enclosingNav.dismiss(animated: true, completion: completion)
            } else {
                thenDisownNavCompletion()
            }
        }

        finishAfterClearingHostedPresentees(from: self) { [weak self] in
            guard let self else {
                completion()
                return
            }
            guard let fallbackNav = self.navigationController else {
                completion()
                return
            }
            if fallbackNav.presentingViewController == nil {
                fallbackNav.popToRootViewController(animated: false)
                completion()
            } else {
                completion()
            }
        }
    }

    private func applyBlockFromMoreMenu() {
        BHFigureBlockShieldStore.block(figureId: figureId)
        finishBlockOrShieldFlow(toast: "已拉黑")
    }

    private func applyShieldFromMoreMenu() {
        BHFigureBlockShieldStore.shield(figureId: figureId)
        finishBlockOrShieldFlow(toast: "已屏蔽")
    }

    private func finishBlockOrShieldFlow(toast: String) {
        NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
        view.cd_showDefaultToast(toast)
        BHBaseTabBarControllerManager.shared.tabBarController.selectedIndex = 0
        bh_dismissFullscreenPresentedHostingStackThenPerform { }
    }

    private func configureFollowHighlightHandlers() {
        followButton.addTarget(self, action: #selector(followTouchDownAction), for: .touchDown)
        followButton.addTarget(self, action: #selector(followTouchUpAction), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside])
    }

    @objc private func followTouchDownAction() {
        UIView.animate(withDuration: 0.08) {
            self.followButton.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.followButton.alpha = 0.78
        }
    }

    @objc private func followTouchUpAction() {
        UIView.animate(withDuration: 0.14, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.followButton.transform = .identity
            self.followButton.alpha = 1
        }
    }

    private func refreshFollowAppearance() {
        var cfg = followButton.configuration ?? .filled()
        let on = BHVideoFigureFollowStore.isFollowing(figureId)
        if on {
            cfg.title = "已关注"
            cfg.baseForegroundColor = .kHexColor(hexString: "#555555")
            cfg.baseBackgroundColor = .kHexColor(hexString: "#EAEAEA")
        } else {
            cfg.title = "关注"
            cfg.baseForegroundColor = .black
            cfg.baseBackgroundColor = BHDetailFigureAppearance.followLimeGreen
        }
        cfg.cornerStyle = .capsule
        cfg.buttonSize = .small
        followButton.configuration = cfg
    }

    @objc private func followTapped() {
        followTouchUpAction()
        let wasFollowing = BHVideoFigureFollowStore.isFollowing(figureId)
        BHVideoFigureFollowStore.setFollowing(!wasFollowing, figureId: figureId)
        refreshFollowAppearance()
        if !wasFollowing {
            view.cd_showDefaultToast("已关注")
        } else {
            view.cd_showDefaultToast("已取消关注")
        }
    }

    @objc private func floatingBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func expandPreviewTapped() {
        view.cd_showDefaultToast("全屏预览（演示）")
    }

    @objc private func messageFloatingTapped() {
        guard let nav = navigationController else {
            view.cd_showDefaultToast("暂时无法打开私信")
            return
        }
        nav.pushViewController(BHFigureMessageViewController(figureId: figureId), animated: true)
    }

    @objc private func tabInfoTapped() {
        selectedTab = 0
        reloadTabUnderline(animated: true)
    }

    @objc private func tabFeedTapped() {
        selectedTab = 1
        reloadTabUnderline(animated: true)
    }

    private func applyTabVisibility() {
        infoScrollView.isHidden = selectedTab != 0
        feedTableView.isHidden = selectedTab != 1
        if selectedTab == 1 {
            feedTableView.reloadData()
            feedTableView.layoutIfNeeded()
        }
        tabInfoButton.titleLabel?.font = .bh_pingFang(size: selectedTab == 0 ? 17 : 15, weight: selectedTab == 0 ? .bold : .regular)
        tabFeedButton.titleLabel?.font = .bh_pingFang(size: selectedTab == 1 ? 17 : 15, weight: selectedTab == 1 ? .bold : .regular)
        tabInfoButton.setTitleColor(selectedTab == 0 ? .black : .kHexColor(hexString: "#888888"), for: .normal)
        tabFeedButton.setTitleColor(selectedTab == 1 ? .black : .kHexColor(hexString: "#888888"), for: .normal)
    }

    private func reloadTabUnderline(animated: Bool) {
        applyTabVisibility()
        let update = {
            self.layoutTabUnderlineFrames()
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: update)
        } else {
            update()
        }
    }

    private func layoutTabUnderlineFrames() {
        guard tabUnderlineView.superview != nil else { return }
        tabInfoButton.layoutIfNeeded()
        tabFeedButton.layoutIfNeeded()
        let btn = selectedTab == 0 ? tabInfoButton : tabFeedButton
        guard let txt = btn.title(for: .normal) else { return }
        let font = btn.titleLabel?.font ?? UIFont.systemFont(ofSize: 16)
        let textW =
            ceil((txt as NSString).boundingRect(with: CGSize(width: 500, height: 40), options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
                .width)
        let underlineW = min(max(textW + kScaleW(10), kScaleW(28)), max(btn.bounds.width - 4, kScaleW(28)))
        let underlineH = kScaleW(4)
        let insetX = (btn.bounds.width - underlineW) / 2
        let underlineFrameBtn = CGRect(
            x: max(0, insetX),
            y: max(0, btn.bounds.height - underlineH - kScaleW(2)),
            width: underlineW,
            height: underlineH
        )
        tabUnderlineView.frame = btn.convert(underlineFrameBtn, to: cardShell)
    }

    private func populateInfoSections() {
        guard let npc else {
            insertSectionTitleLabel("暂无资料信息")
            return
        }

        insertSectionTitleLabel("个人信息")

        let personalRow = BHDetailInfoCardsRow(
            iconNames: ["leaf.fill", "person.crop.circle.fill"],
            texts: [("爱好", npc.hobby), ("性格", npc.personality)]
        )
        infoStackView.addArrangedSubview(personalRow)

        insertSectionTitleLabel("更多照片")
        let gallery = npc.loadGalleryPhotosExcludingAvatar()
        if !gallery.isEmpty {
            let photoRow = BHDetailPhotosRow(images: gallery) { [weak self] index in
                self?.presentGalleryFullscreen(images: gallery, startAt: index)
            }
            infoStackView.addArrangedSubview(photoRow)
            UIView.performWithoutAnimation {
                photoRow.invalidateIntrinsicContentSize()
            }
        }

        insertSectionTitleLabel("视频")
        let neighborId =
            npc.figureId >= 7 ? 6 : npc.figureId + 1
        let vidRow = BHDetailVideoThumbRow(
            movieItem: BHMovieResourceItem(figureId: npc.figureId),
            neighborFigureId: neighborId,
            onTapVideo: { [weak self] item in
                self?.presentFigurePageFullscreenVideo(movieItem: item)
            }
        )
        infoStackView.addArrangedSubview(vidRow)

    }

    private func insertSectionTitleLabel(_ title: String) {
        let l = UILabel()
        l.text = title
        l.font = .bh_pingFang(size: kScaleW(16), weight: .bold)
        l.textColor = .black
        infoStackView.addArrangedSubview(l)
        infoStackView.setCustomSpacing(kScaleW(8), after: l)
    }

    private func presentGalleryFullscreen(images: [UIImage], startAt index: Int) {
        let viewer = BHFullScreenGalleryViewController(images: images, startIndex: index)
        present(viewer, animated: true)
    }

    private func presentFigurePageFullscreenVideo(movieItem: BHMovieResourceItem) {
        guard movieItem.bundleVideoURL() != nil else {
            view.cd_showDefaultToast("无法播放视频")
            return
        }
        let vc = BHHomeVideoShowViewController(movieItem: movieItem)
        let nav = BHBaseNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

private enum BHDetailFigureAppearance {
    static let followLimeGreen = UIColor.kHexColor(hexString: "#C8FB5A")
}

// MARK: - Fullscreen gallery

private final class BHFullScreenGalleryViewController: UIViewController, UIScrollViewDelegate {

    private let galleryImages: [UIImage]
    private let initialIndex: Int
    private let pagingScrollView = UIScrollView()
    private let closeControl = UIButton(type: .system)
    private let ordinalLabel = UILabel()
    private var pageContainers: [UIView] = []
    private var didApplyInitialOffset = false

    init(images: [UIImage], startIndex: Int) {
        self.galleryImages = images
        self.initialIndex = min(max(0, startIndex), max(0, images.count - 1))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        pagingScrollView.isPagingEnabled = true
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.delegate = self
        pagingScrollView.backgroundColor = .black

        closeControl.translatesAutoresizingMaskIntoConstraints = false
        let closeCfg = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        closeControl.setImage(
            UIImage(systemName: "xmark.circle.fill", withConfiguration: closeCfg),
            for: .normal
        )
        closeControl.tintColor = UIColor.white.withAlphaComponent(0.95)
        closeControl.accessibilityLabel = "关闭"
        closeControl.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        ordinalLabel.translatesAutoresizingMaskIntoConstraints = false
        ordinalLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        ordinalLabel.font = .bh_pingFang(size: kScaleW(15), weight: .medium)
        ordinalLabel.textAlignment = .center

        view.addSubview(pagingScrollView)
        view.addSubview(closeControl)
        view.addSubview(ordinalLabel)

        pagingScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            pagingScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: kScaleW(12)),
            closeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: kScaleW(6)),
            closeControl.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            closeControl.heightAnchor.constraint(equalToConstant: kScaleW(44)),

            ordinalLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ordinalLabel.centerYAnchor.constraint(equalTo: closeControl.centerYAnchor),
        ])

        var pages: [UIView] = []

        galleryImages.indices.forEach { idx in
            let pageHost = UIView()
            pageHost.backgroundColor = .black

            let imageView = UIImageView(image: galleryImages[idx])
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .black
            imageView.isAccessibilityElement = true
            imageView.accessibilityLabel = "图片 \(idx + 1)"

            pagingScrollView.addSubview(pageHost)
            pageHost.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: pageHost.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: pageHost.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: pageHost.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: pageHost.bottomAnchor),
            ])

            pages.append(pageHost)
        }

        pageContainers = pages
        ordinalLabel.text = "\(initialIndex + 1) / \(galleryImages.count)"
        view.bringSubviewToFront(closeControl)
        view.bringSubviewToFront(ordinalLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutGalleryPagesIfNeeded()
    }

    private func layoutGalleryPagesIfNeeded() {
        let vw = view.bounds.width
        let vh = view.bounds.height
        guard vw > 0.5, vh > 0.5, !pageContainers.isEmpty else { return }

        pagingScrollView.contentSize = CGSize(width: vw * CGFloat(galleryImages.count), height: vh)

        galleryImages.indices.forEach { idx in
            pageContainers[idx].frame = CGRect(x: CGFloat(idx) * vw, y: 0, width: vw, height: vh)
        }

        if !didApplyInitialOffset {
            pagingScrollView.contentOffset = CGPoint(x: vw * CGFloat(initialIndex), y: 0)
            didApplyInitialOffset = true
        }
        refreshOrdinalLabelForCurrentOffset(width: vw)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func refreshOrdinalLabelForCurrentOffset(width: CGFloat) {
        guard !galleryImages.isEmpty else {
            ordinalLabel.text = ""
            return
        }
        let vw = max(width, 1)
        let rawPage = pagingScrollView.contentOffset.x / vw
        let page = min(max(Int(round(rawPage)), 0), galleryImages.count - 1)
        ordinalLabel.text = "\(page + 1) / \(galleryImages.count)"
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === pagingScrollView else { return }
        refreshOrdinalLabelForCurrentOffset(width: view.bounds.width)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === pagingScrollView, !decelerate else { return }
        refreshOrdinalLabelForCurrentOffset(width: view.bounds.width)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === pagingScrollView else { return }
        refreshOrdinalLabelForCurrentOffset(width: view.bounds.width)
    }
}

// MARK: - Feed

extension BHDetailFigureViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        npc?.moments.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BHDetailMomentPostCell.reuseId,
                for: indexPath
            ) as? BHDetailMomentPostCell,
            let npc,
            npc.moments.indices.contains(indexPath.row)
        else {
            return UITableViewCell()
        }
        let post = npc.moments[indexPath.row]
        cell.configure(post: post, npc: npc, row: indexPath.row)
        let reloadPath = indexPath
        cell.onMomentLikeChanged = { [weak self] in
            self?.feedTableView.reloadRows(at: [reloadPath], with: .none)
        }
        cell.onMomentMoreMenuRequested = { [weak self] button in
            self?.presentFigureMoreActionsActionSheet(from: button)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        kScaleW(240)
    }
}

// MARK: - Info widgets

private final class BHDetailInfoCardsRow: UIView {

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: kScaleW(86))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(iconNames: [String], texts: [(String, String)]) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let outer = UIStackView()
        outer.axis = .horizontal
        outer.spacing = kScaleW(10)
        outer.distribution = .fillEqually
        outer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: topAnchor),
            outer.leadingAnchor.constraint(equalTo: leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor),
            outer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        zip(iconNames, texts).forEach { tuple in
            let (iconName, labeled) = tuple
            outer.addArrangedSubview(
                BHDetailInfoBubbleCard(iconName: iconName, caption: labeled.0, value: labeled.1)
            )
        }
    }
}

private final class BHDetailInfoBubbleCard: UIView {

    init(iconName: String, caption: String, value: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.kHexColor(hexString: "#F3F5F8")
        layer.cornerRadius = kScaleW(12)

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .kHexColor(hexString: "#7A8498")
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let capLab = UILabel()
        capLab.text = caption
        capLab.font = .bh_pingFang(size: kScaleW(12), weight: .medium)
        capLab.textColor = .kHexColor(hexString: "#666666")
        capLab.translatesAutoresizingMaskIntoConstraints = false

        let valLab = UILabel()
        valLab.text = value
        valLab.font = .bh_pingFang(size: kScaleW(13), weight: .regular)
        valLab.textColor = .black
        valLab.numberOfLines = 2
        valLab.lineBreakMode = .byTruncatingTail
        valLab.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIStackView(arrangedSubviews: [icon, capLab])
        topRow.axis = .horizontal
        topRow.spacing = kScaleW(6)
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let vstack = UIStackView(arrangedSubviews: [topRow, valLab])
        vstack.axis = .vertical
        vstack.spacing = kScaleW(8)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vstack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: kScaleW(18)),
            icon.heightAnchor.constraint(equalToConstant: kScaleW(18)),
            vstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kScaleW(12)),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -kScaleW(12)),
            vstack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        heightAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(86)).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class BHDetailPhotosRow: UIView {

    private var imageTapHandler: ((Int) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: kScaleW(100))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(images: [UIImage], onImageTapped: @escaping (Int) -> Void) {
        self.init(frame: .zero)
        imageTapHandler = onImageTapped
        translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = kScaleW(8)
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false

        images.enumerated().forEach { idx, img in
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = kScaleW(8)
            iv.clipsToBounds = true
            iv.isUserInteractionEnabled = true
            iv.accessibilityTraits.insert(.button)
            iv.accessibilityHint = "全屏浏览"
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor, multiplier: 1).isActive = true
            iv.tag = idx

            let tap = UITapGestureRecognizer(target: self, action: #selector(handlePhotoThumbnailTap(_:)))
            iv.addGestureRecognizer(tap)

            row.addArrangedSubview(iv)
        }

        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.heightAnchor.constraint(equalToConstant: kScaleW(96)),
        ])
    }

    @objc private func handlePhotoThumbnailTap(_ recognizer: UITapGestureRecognizer) {
        guard let v = recognizer.view else { return }
        imageTapHandler?(v.tag)
    }
}

private final class BHDetailVideoThumbRow: UIView {

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: kScaleW(200))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(
        movieItem left: BHMovieResourceItem,
        neighborFigureId rightId: Int,
        onTapVideo: @escaping (BHMovieResourceItem) -> Void
    ) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = kScaleW(10)
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(BHDetailVideoBubble(item: left, onTap: onTapVideo))
        row.addArrangedSubview(BHDetailVideoBubble(item: BHMovieResourceItem(figureId: rightId), onTap: onTapVideo))

        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.heightAnchor.constraint(equalToConstant: kScaleW(210)),
        ])
    }
}

private final class BHDetailVideoBubble: UIView {

    private let movieItem: BHMovieResourceItem
    private let onTapHandler: (BHMovieResourceItem) -> Void

    init(item: BHMovieResourceItem, onTap: @escaping (BHMovieResourceItem) -> Void) {
        self.movieItem = item
        self.onTapHandler = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = kScaleW(14)
        iv.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        iv.translatesAutoresizingMaskIntoConstraints = false
        BHMovieThumbnailCache.thumbnail(for: item) { img in
            iv.image = img ?? UIImage(named: "home_top_image")
        }
        let overlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        overlay.tintColor = .white
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isUserInteractionEnabled = false

        addSubview(iv)
        addSubview(overlay)

        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: topAnchor),
            iv.leadingAnchor.constraint(equalTo: leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlay.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: centerYAnchor),
            overlay.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            overlay.heightAnchor.constraint(equalToConstant: kScaleW(44)),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBubbleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
        accessibilityTraits = .button
        accessibilityLabel = "播放视频"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleBubbleTap() {
        onTapHandler(movieItem)
    }
}

// MARK: - Moment cell

private final class BHDetailMomentPostCell: UITableViewCell {

    static let reuseId = "BHDetailMomentPostCell"

    var onMomentLikeChanged: (() -> Void)?
    var onMomentMoreMenuRequested: ((UIButton) -> Void)?

    private var bindFigureId: Int = 0
    private var bindImageAssetName: String?

    private let likeSymbolCfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)

    private let headerAvatarView = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let menuButton = UIButton(type: .system)
    private let thumbButton = UIButton(type: .system)
    private let bodyLabel = UILabel()
    private let topicTagCueLabel = UILabel()
    private let imagesRowStack = UIStackView()
    private let triplePostImages: [UIImageView] = [UIImageView(), UIImageView(), UIImageView()]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white

        headerAvatarView.contentMode = .scaleAspectFill
        headerAvatarView.clipsToBounds = true
        headerAvatarView.layer.cornerRadius = kScaleW(17)

        nameLabel.font = .bh_pingFang(size: kScaleW(15), weight: .medium)
        nameLabel.textColor = .black

        timeLabel.font = .bh_pingFang(size: kScaleW(12), weight: .regular)
        timeLabel.textColor = .kHexColor(hexString: "#979797")

        let moreCfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        menuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: moreCfg), for: .normal)
        menuButton.tintColor = .kHexColor(hexString: "#AAAAAA")
        menuButton.accessibilityLabel = "举报或拉黑屏蔽"
        menuButton.addTarget(self, action: #selector(momentEllipsisMenuTapped), for: .touchUpInside)

        thumbButton.setImage(UIImage(systemName: "hand.thumbsup", withConfiguration: likeSymbolCfg), for: .normal)
        thumbButton.tintColor = .kHexColor(hexString: "#979797")
        thumbButton.addTarget(self, action: #selector(likeThumbTapped), for: .touchUpInside)

        bodyLabel.font = .bh_pingFang(size: kScaleW(15), weight: .regular)
        bodyLabel.textColor = .black
        bodyLabel.numberOfLines = 0

        topicTagCueLabel.font = .bh_pingFang(size: kScaleW(13), weight: .medium)
        topicTagCueLabel.textColor = UIColor.kHexColor(hexString: "#EE6B41")

        imagesRowStack.axis = .horizontal
        imagesRowStack.spacing = kScaleW(6)
        imagesRowStack.distribution = .fillEqually

        for imv in triplePostImages {
            imv.contentMode = .scaleAspectFill
            imv.layer.cornerRadius = kScaleW(6)
            imv.clipsToBounds = true
            imv.translatesAutoresizingMaskIntoConstraints = false
            imagesRowStack.addArrangedSubview(imv)
            imv.heightAnchor.constraint(equalTo: imv.widthAnchor, multiplier: 1).isActive = true
        }

        let topRowRight = UIStackView(arrangedSubviews: [menuButton, thumbButton])
        topRowRight.axis = .horizontal
        topRowRight.spacing = kScaleW(10)

        let nameCol = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        nameCol.axis = .vertical
        nameCol.spacing = kScaleW(2)

        let topRowMid = UIView()
        let topOuter = UIView()
        [headerAvatarView, nameCol, topRowMid, topRowRight].forEach { topOuter.addSubview($0) }
        topRowMid.translatesAutoresizingMaskIntoConstraints = false
        headerAvatarView.translatesAutoresizingMaskIntoConstraints = false
        nameCol.translatesAutoresizingMaskIntoConstraints = false
        topRowRight.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        thumbButton.translatesAutoresizingMaskIntoConstraints = false
        topOuter.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerAvatarView.leadingAnchor.constraint(equalTo: topOuter.leadingAnchor),
            headerAvatarView.topAnchor.constraint(equalTo: topOuter.topAnchor),
            headerAvatarView.widthAnchor.constraint(equalToConstant: kScaleW(34)),
            headerAvatarView.heightAnchor.constraint(equalToConstant: kScaleW(34)),
            headerAvatarView.bottomAnchor.constraint(equalTo: topOuter.bottomAnchor),

            nameCol.leadingAnchor.constraint(equalTo: headerAvatarView.trailingAnchor, constant: kScaleW(8)),
            nameCol.centerYAnchor.constraint(equalTo: headerAvatarView.centerYAnchor),

            topRowMid.leadingAnchor.constraint(equalTo: nameCol.trailingAnchor),
            topRowMid.centerYAnchor.constraint(equalTo: headerAvatarView.centerYAnchor),

            topRowRight.leadingAnchor.constraint(equalTo: topRowMid.trailingAnchor),
            topRowRight.centerYAnchor.constraint(equalTo: headerAvatarView.centerYAnchor),
            topRowRight.trailingAnchor.constraint(equalTo: topOuter.trailingAnchor),
            topRowMid.widthAnchor.constraint(greaterThanOrEqualToConstant: kScaleW(4)),
            menuButton.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            menuButton.heightAnchor.constraint(equalToConstant: kScaleW(36)),
            thumbButton.heightAnchor.constraint(equalToConstant: kScaleW(36)),
            thumbButton.widthAnchor.constraint(equalToConstant: kScaleW(44)),
            thumbButton.leadingAnchor.constraint(equalTo: menuButton.trailingAnchor, constant: kScaleW(4)),
            thumbButton.centerYAnchor.constraint(equalTo: menuButton.centerYAnchor),
            thumbButton.trailingAnchor.constraint(equalTo: topRowRight.trailingAnchor),
        ])

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        topicTagCueLabel.translatesAutoresizingMaskIntoConstraints = false
        imagesRowStack.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.layer.cornerRadius = kScaleW(12)
        card.backgroundColor = .white
        contentView.backgroundColor = .white
        backgroundColor = .white
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [topOuter, topicTagCueLabel, bodyLabel, imagesRowStack])
        stack.axis = .vertical
        stack.spacing = kScaleW(10)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: kScaleW(10)),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -kScaleW(10)),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -kScaleW(14)),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: kScaleW(12)),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: kScaleW(12)),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -kScaleW(12)),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -kScaleW(12)),
            imagesRowStack.heightAnchor.constraint(equalToConstant: kScaleW(108)),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMomentLikeChanged = nil
        onMomentMoreMenuRequested = nil
        bindFigureId = 0
        bindImageAssetName = nil
        bodyLabel.text = ""
        topicTagCueLabel.text = nil
        topicTagCueLabel.isHidden = true
    }

    @objc private func momentEllipsisMenuTapped() {
        onMomentMoreMenuRequested?(menuButton)
    }

    @objc private func likeThumbTapped() {
        BHFigureMomentLikeStore.toggle(figureId: bindFigureId, imageAssetName: bindImageAssetName)
        applyLikeThumbAppearance()
        onMomentLikeChanged?()
    }

    private func applyLikeThumbAppearance() {
        let liked = BHFigureMomentLikeStore.isLiked(figureId: bindFigureId, imageAssetName: bindImageAssetName)
        let name = liked ? "hand.thumbsup.fill" : "hand.thumbsup"
        thumbButton.setImage(UIImage(systemName: name, withConfiguration: likeSymbolCfg), for: .normal)
        thumbButton.setTitle(nil, for: .normal)
        thumbButton.tintColor = liked ? BHDetailFigureAppearance.followLimeGreen : .kHexColor(hexString: "#979797")
    }

    func configure(post: BHFigureMomentPost, npc: BHFigureNPCProfile, row: Int) {
        bindFigureId = npc.figureId
        bindImageAssetName = post.imageAssetName

        headerAvatarView.image = npc.loadAvatarImage()
        nameLabel.text = post.nickname
        bodyLabel.text = post.body

        let trimmedTag = post.tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTag.isEmpty {
            topicTagCueLabel.text = nil
            topicTagCueLabel.isHidden = true
        } else {
            topicTagCueLabel.isHidden = false
            topicTagCueLabel.text = "#\(trimmedTag)"
        }

        switch row % 5 {
        case 0:
            timeLabel.text = "1小时前"
        case 1:
            timeLabel.text = "昨日 18:20"
        case 2:
            timeLabel.text = "3小时前"
        case 3:
            timeLabel.text = "本周"
        default:
            timeLabel.text = "刚刚"
        }

        applyLikeThumbAppearance()

        let asset = post.imageAssetName ?? "man_\(npc.figureId)_2"
        let pic = UIImage(named: asset) ?? npc.loadLastAlbumPhotoOrAvatarFallback()
        triplePostImages[0].image = pic
        triplePostImages[0].isHidden = false
        triplePostImages[1].isHidden = true
        triplePostImages[2].isHidden = true
    }
}
