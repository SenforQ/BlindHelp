//
//  BHMineViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// Tab「我的」根页面。
final class BHMineViewController: BHBaseViewController {

    private enum MineLayout {
        static let hInset = kScaleW(14)
        static let topBgHeight = kScaleW(240)
        static let infoHeight = kScaleW(80)
        static let infoTopAfterNav = kScaleW(14)
        static let avatarSize = kScaleW(80)
        static let blockSpacing = kScaleW(20)
        static let nameTop = kScaleW(15)
        static let signBottomInset = kScaleW(15)
        static let signHeight = kScaleW(20)
        static let nameHeight = kScaleW(25)
        static let editBtnSize = CGSize(width: kScaleW(70), height: kScaleW(28))
        static let textTrailingReserve = kScaleW(100) + kScaleW(82)
        static let serviceCardHeight = kScaleW(128)
        static let otherCardHeight = kScaleW(160)
        static let cardCorner = kScaleW(20)
        static let serviceIcon = kScaleW(44)
        static let serviceItemH = kScaleW(70)
        static let serviceTitleH = kScaleW(17)
        static let sectionTitleTop = kScaleW(14)
        static let sectionTitleH = kScaleW(17)
        static let rowH = kScaleW(40)
        static let rowIcon = kScaleW(20)
        static let arrow = kScaleW(14)
    }

    private lazy var topImgView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "mine_top_bg"))
        v.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: MineLayout.topBgHeight)
        v.contentMode = .scaleAspectFill
        return v
    }()

    private lazy var leftNavTitleLab: UILabel = {
        let lab = UILabel(
            frame: CGRect(
                x: MineLayout.hInset,
                y: kStatusBarHeight + kScaleW(10),
                width: kScaleW(100),
                height: kScaleW(25)
            )
        )
        lab.text = "我的"
        lab.textColor = .kHexColor(hexString: "#000000")
        lab.font = .bh_pingFang(size: 18, weight: .medium)
        lab.textAlignment = .left
        return lab
    }()

    lazy var mineUserAvatarImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: BHUserProfileManager.defaultAvatarAssetName))
        v.contentMode = .scaleAspectFill
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.kHexColor(hexString: "#FFFFFF").cgColor
        v.layer.masksToBounds = true
        return v
    }()

    lazy var mineUserNameLabel: UILabel = {
        let lab = UILabel()
        lab.font = .bh_pingFang(size: 18, weight: .medium)
        lab.text = BHStoredUserProfile.baseline.nickname
        lab.textColor = .kHexColor(hexString: "#000000")
        return lab
    }()

    lazy var mineUserSignLabel: UILabel = {
        let lab = UILabel()
        lab.font = .bh_pingFang(size: 14, weight: .regular)
        lab.text = "签名:暂未签名"
        lab.textColor = .kHexColor(hexString: "#000000")
        return lab
    }()

    private lazy var mineInfoView: UIView = {
        let container = UIView()
        container.frame = CGRect(
            x: 0,
            y: leftNavTitleLab.bottom + MineLayout.infoTopAfterNav,
            width: kScreenWidth,
            height: MineLayout.infoHeight
        )

        let a = mineUserAvatarImageView
        a.frame = CGRect(x: MineLayout.hInset, y: 0, width: MineLayout.avatarSize, height: MineLayout.avatarSize)
        a.layer.cornerRadius = a.bounds.height / 2
        container.addSubview(a)

        let textW = kScreenWidth - MineLayout.textTrailingReserve
        mineUserNameLabel.frame = CGRect(
            x: a.right + kScaleW(10),
            y: MineLayout.nameTop,
            width: textW,
            height: MineLayout.nameHeight
        )
        container.addSubview(mineUserNameLabel)

        mineUserSignLabel.frame = CGRect(
            x: a.right + kScaleW(10),
            y: container.bounds.height - MineLayout.signBottomInset - MineLayout.signHeight,
            width: textW,
            height: MineLayout.signHeight
        )
        container.addSubview(mineUserSignLabel)

        let edit = UIButton(type: .custom)
        let eh = MineLayout.editBtnSize.height
        edit.frame = CGRect(
            x: kScreenWidth - MineLayout.editBtnSize.width,
            y: (container.bounds.height - eh) / 2,
            width: MineLayout.editBtnSize.width,
            height: eh
        )
        edit.setBackgroundImage(UIImage(named: "mine_editor"), for: .normal)
        edit.bh_setTapAction { [weak self] _ in self?.userEditBtnClick() }
        container.addSubview(edit)

        return container
    }()

    private lazy var mineServiceView: UIView = {
        let card = makeWhiteCard(
            top: mineInfoView.bottom + MineLayout.blockSpacing,
            height: MineLayout.serviceCardHeight
        )
        let heading = makeSectionHeading("常用服务")
        card.addSubview(heading)

        let gridX = (card.bounds.width - MineLayout.serviceIcon * 4) / 8
        let y = heading.bottom + kScaleW(14)
        let item0 = makeServiceItem(
            iconName: "mine_service_photo",
            title: "我的相册",
            frame: CGRect(x: gridX, y: y, width: MineLayout.serviceIcon, height: MineLayout.serviceItemH)
        )
        item0.bh_setTapAction { [weak self] _ in self?.servicePhotoBtnClick() }
        card.addSubview(item0)

        let item1 = makeServiceItem(
            iconName: "mine_service_world",
            title: "我的世界",
            frame: CGRect(x: gridX * 2 + item0.right, y: y, width: MineLayout.serviceIcon, height: MineLayout.serviceItemH)
        )
        item1.bh_setTapAction { [weak self] _ in self?.serviceWorldBtnClick() }
        card.addSubview(item1)

        return card
    }()

    private lazy var otherFunctionView: UIView = {
        let card = makeWhiteCard(
            top: mineServiceView.bottom + MineLayout.blockSpacing,
            height: MineLayout.otherCardHeight
        )
        let heading = makeSectionHeading("其他功能")
        card.addSubview(heading)

        var y = heading.bottom + kScaleW(4)
        y += addArrowSettingsRow(
            to: card,
            y: y,
            iconName: "mine_contactCustomer",
            title: "联系客服",
            action: { [weak self] in self?.contactCustomerBtnClick() }
        )
        y += addArrowSettingsRow(
            to: card,
            y: y,
            iconName: "mine_privacyPolicy",
            title: "隐私政策",
            action: { [weak self] in self?.privacyPolicyBtnClick() }
        )
        _ = addArrowSettingsRow(
            to: card,
            y: y,
            iconName: "mine_userAgreement",
            title: "用户协议",
            action: { [weak self] in self?.userTermsBtnClick() }
        )

        return card
    }()

    private lazy var bottomTabBar: BHCustomBottomTabBarView = {
        let bar = BHCustomBottomTabBarView(host: self, selectedMainTab: .mine)
        bar.onPhotoButtonTapped = {
            print("点击拍照")
        }
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .kHexColor(hexString: "#F7F7F7")
        view.addSubview(topImgView)
        view.addSubview(leftNavTitleLab)
        view.addSubview(mineInfoView)
        view.addSubview(mineServiceView)
        view.addSubview(otherFunctionView)
        view.addSubview(bottomTabBar)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncMineProfileFromStore()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomTabBar.layoutFrame(in: view.bounds)
        bh_bringCustomTabBarToFront(bottomTabBar)
    }

    private func makeWhiteCard(top: CGFloat, height: CGFloat) -> UIView {
        let w = kScreenWidth - MineLayout.hInset * 2
        let v = UIView(frame: CGRect(x: MineLayout.hInset, y: top, width: w, height: height))
        v.layer.cornerRadius = MineLayout.cardCorner
        v.layer.masksToBounds = true
        v.backgroundColor = .kHexColor(hexString: "#FFFFFF")
        return v
    }

    private func makeSectionHeading(_ text: String) -> UILabel {
        let lab = UILabel(
            frame: CGRect(
                x: MineLayout.hInset,
                y: MineLayout.sectionTitleTop,
                width: kScaleW(100),
                height: MineLayout.sectionTitleH
            )
        )
        lab.text = text
        lab.textAlignment = .left
        lab.font = .bh_pingFang(size: 12, weight: .regular)
        lab.textColor = .kHexColor(hexString: "#111111")
        return lab
    }

    private func makeServiceItem(iconName: String, title: String, frame: CGRect) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.frame = frame
        let iv = UIImageView(image: UIImage(named: iconName))
        iv.contentMode = .scaleAspectFill
        iv.frame = CGRect(x: 0, y: 0, width: MineLayout.serviceIcon, height: MineLayout.serviceIcon)
        btn.addSubview(iv)
        let lab = UILabel(
            frame: CGRect(
                x: -kScaleW(12),
                y: btn.bounds.height - MineLayout.serviceTitleH,
                width: btn.bounds.width + kScaleW(24),
                height: MineLayout.serviceTitleH
            )
        )
        lab.text = title
        lab.font = .bh_pingFang(size: 12, weight: .regular)
        lab.textColor = .kHexColor(hexString: "#111111")
        lab.textAlignment = .center
        btn.addSubview(lab)
        return btn
    }

    @discardableResult
    private func addArrowSettingsRow(
        to card: UIView,
        y: CGFloat,
        iconName: String,
        title: String,
        action: @escaping () -> Void
    ) -> CGFloat {
        let h = MineLayout.rowH
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 0, y: y, width: card.bounds.width, height: h)
        btn.bh_setTapAction { _ in action() }

        let icon = UIImageView(image: UIImage(named: iconName))
        icon.contentMode = .scaleAspectFill
        icon.frame = CGRect(x: MineLayout.hInset, y: kScaleW(10), width: MineLayout.rowIcon, height: MineLayout.rowIcon)
        btn.addSubview(icon)

        let lab = UILabel(
            frame: CGRect(
                x: icon.right + kScaleW(10),
                y: kScaleW(10),
                width: kScaleW(150),
                height: MineLayout.serviceTitleH
            )
        )
        lab.text = title
        lab.font = .bh_pingFang(size: 12, weight: .regular)
        lab.textColor = .kHexColor(hexString: "#111111")
        lab.textAlignment = .left
        btn.addSubview(lab)

        let arrow = UIImageView(image: UIImage(named: "mine_right_arrow"))
        arrow.contentMode = .scaleAspectFill
        arrow.frame = CGRect(
            x: btn.bounds.width - MineLayout.hInset - MineLayout.arrow,
            y: (h - MineLayout.arrow) / 2,
            width: MineLayout.arrow,
            height: MineLayout.arrow
        )
        btn.addSubview(arrow)

        card.addSubview(btn)
        return h
    }
}

private extension BHMineViewController {
    @objc func syncMineProfileFromStore() {
        let p = BHUserProfileManager.shared.currentProfileSnapshot()
        mineUserNameLabel.text = p.nickname
        if p.signature.isEmpty {
            mineUserSignLabel.text = "签名:暂未签名"
        } else {
            mineUserSignLabel.text = "签名:" + p.signature
        }
        mineUserAvatarImageView.image = BHUserProfileManager.shared.loadAvatarForDisplay()
    }

    func userEditBtnClick() {
        debugPrint("个人主页")
        let vc = BHMineEditorInfoViewController.init()
        vc.title = "编辑资料"
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func servicePhotoBtnClick() {
        let vc = BHMinePhotoViewController()
        vc.title = "我的相册"
        navigationController?.pushViewController(vc, animated: true)
    }

    func serviceWorldBtnClick() {
        let vc = BHMineWorldViewController()
        vc.title = "我的世界"
        navigationController?.pushViewController(vc, animated: true)
    }

    func contactCustomerBtnClick() {
        let vc = BHContactCustomerViewController()
        vc.title = "联系客服"
        navigationController?.pushViewController(vc, animated: true)
    }

    func privacyPolicyBtnClick() {
        let vc = BHMinePrivateViewController()
        vc.title = "隐私政策"
        navigationController?.pushViewController(vc, animated: true)
    }

    func userTermsBtnClick() {
        let vc = BHMineUserTermsViewController()
        vc.title = "用户协议"
        navigationController?.pushViewController(vc, animated: true)
    }
}
