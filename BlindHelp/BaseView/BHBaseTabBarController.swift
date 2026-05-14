//
//  BHBaseTabBarController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// TabBar 单例管理器：保证全进程共用一个 `BHBaseTabBarController` 实例，便于从任意处取根 Tab。
final class BHBaseTabBarControllerManager {
    static let shared = BHBaseTabBarControllerManager()

    private init() {
        _ = tabBarController
    }

    /// 懒加载的 TabBar 根控制器，首次访问时创建并完成基础配置。
    lazy var tabBarController: BHBaseTabBarController = {
        let tabBarController = BHBaseTabBarController()
        tabBarController.selectedIndex = 0
        return tabBarController
    }()
}

/// 应用主 TabBar：封装角标颜色、子页装配与 Tab 切换无动画过渡（时长为 0 的自定义转场）。
final class BHBaseTabBarController: UITabBarController {

    // MARK: - 外观

    /// Tab 选中时标题与着色使用的主色。
    let selectItemColor: UIColor = .kHexColor(hexString: "#FF8B00")

    /// Tab 未选中时标题颜色。
    let unSelectItemColor: UIColor = .kHexColor(hexString: "#AEAEAE")

    /// 是否已写入 `viewControllers`，防止重复装配 Tab。
    private var didConfigureChildControllers = false

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabBarAppearance()
    }

    // MARK: - 配置

    /// 设置 TabBar 条外观；默认隐藏底部 Tab 条（仍保留多个子导航栈，通过 `selectedIndex` 切换）。
    private func setupTabBarAppearance() {
        tabBar.isHidden = true
        tabBar.backgroundColor = .kHexColor(hexString: "#FFFFFF")
    }

    /// 若尚未添加子控制器，则创建首页、广场、消息、我的四个 Navigation + 业务页。
    func createChildViewControllersIfNeeded() {
        guard !didConfigureChildControllers else { return }

        let tabs: [BHBaseNavigationController] = [
            makeTabNavigation(
                title: "",
                tabBarItemTitle: "首页",
                normalImageName: "tab_home_n",
                selectedImageName: "tab_home_s",
                root: BHHomePageViewController()
            ),
            makeTabNavigation(
                title: "",
                tabBarItemTitle: "广场",
                normalImageName: "tab_square_n",
                selectedImageName: "tab_square_s",
                root: BHDiscoverViewController()
            ),
            makeTabNavigation(
                title: "",
                tabBarItemTitle: "消息",
                normalImageName: "tab_message_n",
                selectedImageName: "tab_message_s",
                root: BHMessageViewController()
            ),
            makeTabNavigation(
                title: "",
                tabBarItemTitle: "我的",
                normalImageName: "tab_mine_n",
                selectedImageName: "tab_mine_s",
                root: BHMineViewController()
            ),
        ]

        viewControllers = tabs
        tabBar.tintColor = selectItemColor
        tabBar.unselectedItemTintColor = unSelectItemColor
        tabs.forEach { nav in
            if let item = nav.topViewController?.tabBarItem ?? nav.tabBarItem {
                setupTabBarItemAppearance(item: item)
            }
        }

        didConfigureChildControllers = true
    }

    /// 构造单个 Tab：在根 VC 上配置 `tabBarItem`（系统会从 Navigation 的 topViewController 继承），再包一层 `BHBaseNavigationController`。
    private func makeTabNavigation(
        title: String,
        tabBarItemTitle: String,
        normalImageName: String,
        selectedImageName: String,
        root: UIViewController
    ) -> BHBaseNavigationController {
        root.title = title
        root.tabBarItem.title = tabBarItemTitle
        root.tabBarItem.image = UIImage(named: normalImageName)?.withRenderingMode(.alwaysOriginal)
        root.tabBarItem.selectedImage = UIImage(named: selectedImageName)?.withRenderingMode(.alwaysOriginal)
        return BHBaseNavigationController(rootViewController: root)
    }

    /// 对单个 `UITabBarItem` 设置选中文案与未选中文案颜色。
    func setupTabBarItemAppearance(item: UITabBarItem) {
        item.setTitleTextAttributes(
            [NSAttributedString.Key.foregroundColor: selectItemColor],
            for: .selected
        )
        item.setTitleTextAttributes(
            [NSAttributedString.Key.foregroundColor: unSelectItemColor],
            for: .normal
        )
    }
}

// MARK: - UITabBarControllerDelegate

extension BHBaseTabBarController: UITabBarControllerDelegate {

    func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension BHBaseTabBarController: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        transitionContext.containerView.addSubview(toView)
        transitionContext.completeTransition(true)
    }
}
