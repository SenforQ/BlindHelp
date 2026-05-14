//
//  BHBaseNavigationBar.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 应用内统一自定义导航栏：含居中标题与左侧返回（资源 `nav_black_back_left`）。
final class PEBaseNavigationBar: UIView {

    /// 实际承载标题与按钮的容器，整体上移 `kStatusBarHeight` 以避开状态栏。
    lazy var navigationView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: kStatusBarHeight, width: kScreenWidth, height: kNavBarHeight)
        view.backgroundColor = .clear
        return view
    }()

    /// 导航标题，固定宽度居中于 `navigationView`。
    lazy var navTitleLab: UILabel = {
        let label = UILabel()
        let titleWidth = kScaleW(200)
        label.frame = CGRect(
            x: (kScreenWidth - titleWidth) / 2.0,
            y: 0,
            width: titleWidth,
            height: kNavBarHeight
        )
        label.font = .bh_pingFang(size: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .kHexColor(hexString: "#000000")
        return label
    }()

    /// 返回按钮：默认隐藏，由 `BHBaseNavigationController` 在非根页显示。
    lazy var navLeftBtn: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: kScaleW(13), y: 0, width: kNavBarHeight, height: kNavBarHeight)
        button.isHidden = true
        button.addTarget(self, action: #selector(navBackArrowClick), for: .touchUpInside)

        let imageView = UIImageView(image: UIImage(named: "nav_arrow_left"))
        let imageSize = kScaleW(24)
        imageView.frame = CGRect(
            x: 0,
            y: (button.height - imageSize) / 2.0,
            width: imageSize,
            height: imageSize
        )
        button.addSubview(imageView)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(navigationView)
        navigationView.addSubview(navTitleLab)
        navigationView.addSubview(navLeftBtn)
    }

    /// 返回：模态则 dismiss，否则 navigationController pop；非 `BHBaseViewController` 时降级为系统 pop。
    @objc private func navBackArrowClick() {
        guard let currentVC = BHWindowsManager.currentVC as? BHBaseViewController else {
            BHWindowsManager.currentVC?.navigationController?.popViewController(animated: true)
            return
        }

        if currentVC.isPresentVC {
            currentVC.dismiss(animated: true)
        } else {
            currentVC.navigationController?.popViewController(animated: true)
        }
    }
}
