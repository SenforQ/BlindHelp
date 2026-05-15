//
//  BHHomeVideoShowViewController.swift
//  BlindHelp
//

import AVFoundation
import UIKit

final class BHHomeVideoShowViewController: UIViewController {

    private let movieItem: BHMovieResourceItem

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerRateObservation: NSKeyValueObservation?
    private let videoContainer = UIView()
    private let bottomGradient = CAGradientLayer()
    private var endObserver: NSObjectProtocol?

    private let centerPlayButton = UIButton(type: .system)
    private let backNavButton = UIButton(type: .system)
    private let leftStack = UIStackView()

    private let nickRow = UIStackView()
    private let nicknameLabel = UILabel()
    private let diamondView = UIImageView()
    private let feelingLabel = UILabel()

    private let avatarOuter = UIView()
    private let avatarView = UIImageView()
    private let rightColumn = UIView()
    private let followControl = UIControl()
    private let followIconBox = UIView()
    private let followIcon = UIImageView()
    private let followText = UILabel()
    private let profileControl = UIControl()
    private let profileIconBox = UIView()
    private let profileIcon = UIImageView()
    private let profileText = UILabel()

    private let moreActionButton = UIButton(type: .system)

    private let tapToTogglePlay = UITapGestureRecognizer()

    init(movieItem: BHMovieResourceItem) {
        self.movieItem = movieItem
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(videoContainer)
        setupPlayerIfPossible()
        videoContainer.layer.insertSublayer(bottomGradient, at: 1)
        bottomGradient.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.45).cgColor,
            UIColor.black.withAlphaComponent(0.62).cgColor,
        ]
        bottomGradient.locations = [0, 0.55, 1]
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1)

        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)

        backNavButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        backNavButton.tintColor = .white
        backNavButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backNavButton.accessibilityLabel = "返回"
        view.addSubview(backNavButton)

        configureLeftContent()
        configureRightContent()
        view.addSubview(leftStack)
        view.addSubview(rightColumn)

        tapToTogglePlay.addTarget(self, action: #selector(togglePlay))
        tapToTogglePlay.cancelsTouchesInView = false
        videoContainer.addGestureRecognizer(tapToTogglePlay)

        let playCfgLarge = UIImage.SymbolConfiguration(pointSize: kScaleW(72), weight: .regular)
        centerPlayButton.setImage(
            UIImage(systemName: "play.circle.fill", withConfiguration: playCfgLarge),
            for: .normal
        )
        centerPlayButton.tintColor = UIColor.white.withAlphaComponent(0.92)
        centerPlayButton.adjustsImageWhenHighlighted = false
        centerPlayButton.backgroundColor = .clear
        centerPlayButton.accessibilityLabel = "播放"
        centerPlayButton.addTarget(self, action: #selector(centerPlayTapped), for: .touchUpInside)
        centerPlayButton.isHidden = true
        centerPlayButton.isUserInteractionEnabled = false

        videoContainer.addSubview(centerPlayButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoContainer.frame = view.bounds
        playerLayer?.frame = videoContainer.bounds
        bottomGradient.frame = CGRect(
            x: 0,
            y: view.bounds.height - kScaleW(340),
            width: view.bounds.width,
            height: kScaleW(340)
        )

        let playBtnSide = kScaleW(104)
        centerPlayButton.bounds = CGRect(x: 0, y: 0, width: playBtnSide, height: playBtnSide)
        centerPlayButton.center = CGPoint(x: videoContainer.bounds.midX, y: videoContainer.bounds.midY)

        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let side = kScaleW(16)
        let marginAboveHomeIndicator = safeBottom + kScaleW(28)

        let navTop = safeTop + kScaleW(8)
        let navH = kScaleW(44)
        let navW = kScaleW(44)
        backNavButton.frame = CGRect(x: max(side - kScaleW(4), 0), y: navTop, width: navW, height: navH)

        let rightW = kScaleW(72)
        let columnRight = view.bounds.width - kScaleW(10)

        let avatarSize = kScaleW(54)
        let iconBlockSide = kScaleW(42)
        let ctlH = iconBlockSide + kScaleW(20)
        let spacingTight = kScaleW(6)
        let spacingMid = kScaleW(10)
        let moreRowH = kScaleW(44)

        let stackHeight =
            avatarSize +
            spacingMid +
            ctlH +
            spacingMid +
            ctlH +
            spacingMid +
            moreRowH +
            spacingTight

        let columnBottomY = view.bounds.height - marginAboveHomeIndicator
        let columnY = columnBottomY - stackHeight

        rightColumn.frame = CGRect(
            x: columnRight - rightW,
            y: columnY,
            width: rightW,
            height: stackHeight
        )

        let maxLeftW = max(0, rightColumn.frame.minX - side - kScaleW(10))

        func layoutFooterStackFromBottomUp() -> CGFloat {
            let bottomPad = spacingTight
            var yBottom = stackHeight - bottomPad

            moreActionButton.bounds = CGRect(x: 0, y: 0, width: rightW, height: moreRowH)
            moreActionButton.frame.origin = CGPoint(x: 0, y: yBottom - moreRowH)
            yBottom = moreActionButton.frame.minY - spacingMid

            profileControl.bounds = CGRect(x: 0, y: 0, width: kScaleW(72), height: ctlH)
            profileControl.frame.origin = CGPoint(
                x: (rightW - kScaleW(72)) / 2,
                y: yBottom - ctlH
            )

            profileIconBox.frame = CGRect(
                x: (profileControl.bounds.width - iconBlockSide) / 2,
                y: 0,
                width: iconBlockSide,
                height: iconBlockSide
            )
            profileIcon.frame = CGRect(
                x: (iconBlockSide - kScaleW(26)) / 2,
                y: kScaleW(8),
                width: kScaleW(26),
                height: kScaleW(26)
            )
            profileText.frame = CGRect(
                x: 0,
                y: profileIconBox.frame.maxY + kScaleW(2),
                width: kScaleW(72),
                height: kScaleW(17)
            )

            yBottom = profileControl.frame.minY - spacingMid

            followControl.bounds = CGRect(x: 0, y: 0, width: kScaleW(72), height: ctlH)
            followControl.frame.origin = CGPoint(x: (rightW - kScaleW(72)) / 2, y: yBottom - ctlH)

            followIconBox.frame = CGRect(
                x: (followControl.bounds.width - iconBlockSide) / 2,
                y: 0,
                width: iconBlockSide,
                height: iconBlockSide
            )
            followIcon.frame = CGRect(
                x: (iconBlockSide - kScaleW(26)) / 2,
                y: kScaleW(8),
                width: kScaleW(26),
                height: kScaleW(26)
            )
            followText.frame = CGRect(
                x: 0,
                y: followIconBox.frame.maxY + kScaleW(2),
                width: kScaleW(72),
                height: kScaleW(17)
            )

            yBottom = followControl.frame.minY - spacingMid

            avatarOuter.frame = CGRect(
                x: (rightW - avatarSize) / 2,
                y: max(0, yBottom - avatarSize),
                width: avatarSize,
                height: avatarSize
            )

            avatarView.frame = avatarOuter.bounds
            return avatarOuter.frame.minY
        }

        _ = layoutFooterStackFromBottomUp()

        let targetLeftBottom = columnBottomY
        feelingLabel.preferredMaxLayoutWidth = maxLeftW
        let leftFit = leftStack.systemLayoutSizeFitting(
            CGSize(width: maxLeftW, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let leftH = max(kScaleW(56), ceil(leftFit.height))
        leftStack.bounds.size = CGSize(width: maxLeftW, height: leftH)
        leftStack.frame.origin = CGPoint(
            x: side,
            y: targetLeftBottom - leftStack.bounds.height
        )
        leftStack.setNeedsLayout()
        leftStack.layoutIfNeeded()
        videoContainer.bringSubviewToFront(centerPlayButton)
        view.bringSubviewToFront(leftStack)
        view.bringSubviewToFront(rightColumn)
        view.bringSubviewToFront(backNavButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFollowAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        player?.play()
        DispatchQueue.main.async { [weak self] in
            guard let self, let player = self.player else { return }
            self.updateCenterPlayVisibility(isPlaying: player.rate > 0.01)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        player?.pause()
    }

    @MainActor deinit {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playerRateObservation?.invalidate()
        playerRateObservation = nil
    }

    private func setupPlayerIfPossible() {
        guard let url = movieItem.bundleVideoURL() else {
            DispatchQueue.main.async {
                self.view.cd_showDefaultToast("无法播放视频")
                self.dismiss(animated: true)
            }
            return
        }
        let player = AVPlayer(url: url)
        playerRateObservation?.invalidate()
        playerRateObservation = player.observe(\.rate, options: [.new]) { [weak self] p, _ in
            DispatchQueue.main.async {
                self?.updateCenterPlayVisibility(isPlaying: p.rate > 0.01)
            }
        }
        self.player = player
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = videoContainer.bounds
        videoContainer.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        let item = player.currentItem
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.player?.seek(to: .zero)
            self.player?.play()
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let err = (note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription ?? "播放失败"
            self.view.cd_showDefaultToast(err)
        }
    }

    private func configureLeftContent() {
        let profile = BHFigureResourceCatalog.profile(figureId: movieItem.figureId)

        nicknameLabel.font = .bh_pingFang(size: 17, weight: .bold)
        nicknameLabel.textColor = .white
        nicknameLabel.text = "@\(profile?.nickname ?? "旅友")"

        let dCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        diamondView.image = UIImage(systemName: "diamond.fill", withConfiguration: dCfg)
        diamondView.tintColor = UIColor.kHexColor(hexString: "#F5D76E")
        diamondView.contentMode = .scaleAspectFit
        diamondView.setContentHuggingPriority(.required, for: .horizontal)

        nickRow.axis = .horizontal
        nickRow.alignment = .center
        nickRow.spacing = kScaleW(6)
        nickRow.addArrangedSubview(nicknameLabel)
        nickRow.addArrangedSubview(diamondView)

        feelingLabel.font = .bh_pingFang(size: 14, weight: .regular)
        feelingLabel.textColor = UIColor.white.withAlphaComponent(0.94)
        feelingLabel.numberOfLines = 2
        if let sig = profile?.signature, !sig.isEmpty {
            feelingLabel.text = sig
        } else {
            feelingLabel.text = "喜欢用镜头记录每一段路上的光和故事。"
        }

        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = kScaleW(10)
        leftStack.addArrangedSubview(nickRow)
        leftStack.addArrangedSubview(feelingLabel)
        leftStack.clipsToBounds = true
    }
    private func configureRightContent() {
        let profile = BHFigureResourceCatalog.profile(figureId: movieItem.figureId)

        avatarOuter.backgroundColor = .clear
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.white.cgColor
        avatarView.layer.cornerRadius = kScaleW(28)
        avatarView.image = profile?.loadAvatarImage() ?? UIImage(named: "applogo")
        avatarOuter.addSubview(avatarView)

        let starCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        followIcon.image = UIImage(systemName: "star.fill", withConfiguration: starCfg)
        followIcon.tintColor = .white
        followIconBox.backgroundColor = .clear
        followIconBox.clipsToBounds = false
        followIconBox.isUserInteractionEnabled = false
        followIconBox.addSubview(followIcon)

        followText.text = "关注"
        followText.font = .bh_pingFang(size: 12, weight: .medium)
        followText.textColor = .white
        followText.textAlignment = .center
        followText.isUserInteractionEnabled = false
        followControl.addSubview(followIconBox)
        followControl.addSubview(followText)
        followControl.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        followControl.addTarget(self, action: #selector(hudTouchDown(_:)), for: .touchDown)
        followControl.addTarget(self, action: #selector(hudTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        refreshFollowAppearance()

        let pCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        profileIcon.image = UIImage(systemName: "person.crop.circle", withConfiguration: pCfg)
        profileIcon.tintColor = .white
        profileIconBox.backgroundColor = .clear
        profileIconBox.isUserInteractionEnabled = false
        profileIconBox.addSubview(profileIcon)

        profileText.text = "查看主页"
        profileText.font = .bh_pingFang(size: 12, weight: .medium)
        profileText.textColor = .white
        profileText.textAlignment = .center
        profileText.isUserInteractionEnabled = false

        profileControl.addSubview(profileIconBox)
        profileControl.addSubview(profileText)
        profileControl.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        profileControl.addTarget(self, action: #selector(hudTouchDown(_:)), for: .touchDown)
        profileControl.addTarget(self, action: #selector(hudTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        followIcon.autoresizingMask = []
        profileIcon.autoresizingMask = []

        profileIcon.isUserInteractionEnabled = false

        rightColumn.backgroundColor = .clear
        rightColumn.isUserInteractionEnabled = true
        avatarOuter.isUserInteractionEnabled = false
        avatarView.isUserInteractionEnabled = false
        followIcon.isUserInteractionEnabled = false
        followControl.isUserInteractionEnabled = true
        profileControl.isUserInteractionEnabled = true

        let alertSymCfg = UIImage.SymbolConfiguration(pointSize: kScaleW(26), weight: .semibold)
        moreActionButton.setImage(
            UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: alertSymCfg),
            for: .normal
        )
        moreActionButton.tintColor = UIColor.systemRed
        moreActionButton.adjustsImageWhenHighlighted = false
        moreActionButton.accessibilityLabel = "举报或拉黑屏蔽"
        moreActionButton.addTarget(self, action: #selector(moreActionTapped), for: .touchUpInside)

        rightColumn.addSubview(avatarOuter)
        rightColumn.addSubview(followControl)
        rightColumn.addSubview(profileControl)
        rightColumn.addSubview(moreActionButton)
    }
    @objc private func closeTapped() {
        if let nav = navigationController {
            nav.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func togglePlay() {
        guard let player else { return }
        if player.rate > 0.01 {
            player.pause()
        } else {
            player.play()
        }
    }

    @objc private func centerPlayTapped() {
        player?.play()
    }

    private func updateCenterPlayVisibility(isPlaying: Bool) {
        centerPlayButton.isHidden = isPlaying
        centerPlayButton.alpha = isPlaying ? 0 : 1
        centerPlayButton.isUserInteractionEnabled = !isPlaying
    }

    private func refreshFollowAppearance() {
        let on = BHVideoFigureFollowStore.isFollowing(movieItem.figureId)
        followIcon.tintColor =
            on
                ? UIColor.kHexColor(hexString: "#F5D76E")
                : .white
        followText.text = on ? "已关注" : "关注"
    }

    @objc private func hudTouchDown(_ sender: UIControl) {
        UIView.animate(withDuration: 0.08) {
            sender.alpha = 0.74
            self.followIconBox.transform = sender === self.followControl
                ? CGAffineTransform(scaleX: 0.94, y: 0.94)
                : .identity
            self.profileIconBox.transform = sender === self.profileControl
                ? CGAffineTransform(scaleX: 0.94, y: 0.94)
                : .identity
        }
    }

    @objc private func hudTouchUp(_ sender: UIControl) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            sender.alpha = 1
            self.followIconBox.transform = .identity
            self.profileIconBox.transform = .identity
        }
    }

    @objc private func followTapped() {
        hudTouchUp(followControl)
        let id = movieItem.figureId
        let was = BHVideoFigureFollowStore.isFollowing(id)
        BHVideoFigureFollowStore.setFollowing(!was, figureId: id)
        refreshFollowAppearance()
        if !was {
            view.cd_showDefaultToast("已关注")
        } else {
            view.cd_showDefaultToast("已取消关注")
        }
    }

    @objc private func profileTapped() {
        hudTouchUp(profileControl)
        guard let nav = navigationController else {
            view.cd_showDefaultToast("无法打开主页")
            return
        }
        let detail = BHDetailFigureViewController(figureId: movieItem.figureId)
        nav.pushViewController(detail, animated: true)
    }

    @objc private func moreActionTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "举报", style: .default) { [weak self] _ in
            self?.openFigureReportPageFromVideoMoreMenu()
        })
        sheet.addAction(UIAlertAction(title: "拉黑", style: .destructive) { [weak self] _ in
            self?.applyVideoMenuBlockFigure()
        })
        sheet.addAction(UIAlertAction(title: "屏蔽", style: .destructive) { [weak self] _ in
            self?.applyVideoMenuShieldFigure()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = moreActionButton
            pop.sourceRect = moreActionButton.bounds
            pop.permittedArrowDirections = [.down, .up]
        }
        present(sheet, animated: true)
    }

    private func openFigureReportPageFromVideoMoreMenu() {
        guard let nav = navigationController else {
            view.cd_showDefaultToast("无法打开举报页")
            return
        }
        let profile = BHFigureResourceCatalog.profile(figureId: movieItem.figureId)
        let name = profile?.nickname ?? "旅友"
        let report = BHFigureReportViewController(figureId: movieItem.figureId, targetDisplayName: name)
        nav.pushViewController(report, animated: true)
    }

    private func applyVideoMenuBlockFigure() {
        BHFigureBlockShieldStore.block(figureId: movieItem.figureId)
        finishVideoBlockOrShieldFlow(toastText: "已拉黑")
    }

    private func applyVideoMenuShieldFigure() {
        BHFigureBlockShieldStore.shield(figureId: movieItem.figureId)
        finishVideoBlockOrShieldFlow(toastText: "已屏蔽")
    }

    private func finishVideoBlockOrShieldFlow(toastText: String) {
        NotificationCenter.default.post(name: .bhHomeFigureBlockedOrShieldedListDidChange, object: nil)
        view.cd_showDefaultToast(toastText)
        if let nav = navigationController {
            nav.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
