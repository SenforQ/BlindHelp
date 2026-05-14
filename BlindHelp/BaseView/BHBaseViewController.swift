//
//  BHBaseViewController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 业务页面基类：统一铺满顶部/主体背景图，并挂载自定义导航栏 `PEBaseNavigationBar`。
class BHBaseViewController: UIViewController {

    /// 是否允许 interactive pop 侧滑返回（由 `BHBaseNavigationController` 读取）。
    var isCanGestureBack = true

    /// 是否为以 `present` 方式展示的页面（影响返回按钮是 pop 还是 dismiss）。
    var isPresentVC = false

    /// 页面顶部装饰背景（与资源 `base_top_bg` 对应）。
    lazy var baseBackgroundTopImgV: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "base_top_bg"))
        imageView.contentMode = .scaleToFill
        imageView.isHidden = false
        return imageView
    }()

    /// 页面主体渐变/底纹背景（与资源 `base_liner_bg` 对应）。
    lazy var baseBackgroundBodyImgV: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "base_liner_bg"))
        imageView.contentMode = .scaleToFill
        imageView.isHidden = false
        return imageView
    }()

    /// 自定义导航栏（标题、返回按钮），高度为状态栏 + 导航条区域。
    lazy var kdNavBar: PEBaseNavigationBar = {
        let navBarView = PEBaseNavigationBar(
            frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kNavBarFullHeight)
        )
        return navBarView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBodyView()
        setupSubConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationTitle()
    }

    /// 白底 + 背景图 + 导航栏添加到根视图。
    private func setupUI() {
        view.backgroundColor = .kHexColor(hexString: "#F7F7F7")
        view.addSubview(baseBackgroundBodyImgV)
        baseBackgroundBodyImgV.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        view.addSubview(baseBackgroundTopImgV)
        baseBackgroundTopImgV.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScaleW(300))
        view.addSubview(kdNavBar)
    }

    /// 若自定义标题文案为空，则用 `UIViewController.title` 同步到导航栏标题 Label。
    private func updateNavigationTitle() {
        if kdNavBar.navTitleLab.text?.isEmpty ?? true {
            kdNavBar.navTitleLab.text = title
        }
    }

    /// 子类在此添加业务内容视图。
    func setupBodyView() {
    }

    /// 子类在此使用 AutoLayout 或其它方式约束子视图。
    func setupSubConstraints() {
    }
}
