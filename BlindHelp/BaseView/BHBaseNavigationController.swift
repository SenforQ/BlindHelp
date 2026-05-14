//
//  BHBaseNavigationController.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 全局导航容器：隐藏系统导航栏，使用业务里的自定义导航条；并配置侧滑返回与 `hidesBottomBarWhenPushed`。
final class BHBaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupGestureRecognizer()
    }

    /// 完全使用自定义导航 UI，系统 `UINavigationBar` 始终隐藏。
    private func setupNavigationBar() {
        setNavigationBarHidden(true, animated: false)
    }

    /// 侧滑返回手势由本类 + `BHBaseViewController.isCanGestureBack` 协同控制。
    private func setupGestureRecognizer() {
        let selector = NSSelectorFromString("interactivePopGestureRecognizer")
        guard responds(to: selector) else { return }

        interactivePopGestureRecognizer?.delegate = self
        delegate = self
    }

    /// 入栈时：非根控制器默认隐藏底部 TabBar；根页上的自定义返回按钮保持隐藏。
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if children.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
            if let baseVC = viewController as? BHBaseViewController {
                baseVC.kdNavBar.navLeftBtn.isHidden = false
            }
        }else{
            viewController.hidesBottomBarWhenPushed = true
        }

        super.pushViewController(viewController, animated: animated)
    }
}

// MARK: - UINavigationControllerDelegate

extension BHBaseNavigationController: UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        let selector = NSSelectorFromString("interactivePopGestureRecognizer")
        if responds(to: selector) {
            interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BHBaseNavigationController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }

    /// 侧滑返回：仅处理系统 `interactivePopGestureRecognizer`；栈深为 1 时若为模态展示的 `BHBaseViewController` 则 dismiss。
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let selector = NSSelectorFromString("interactivePopGestureRecognizer")
        guard responds(to: selector) else { return false }

        guard gestureRecognizer == interactivePopGestureRecognizer else {
            return false
        }

        let currentVC = topViewController

        if viewControllers.count == 1 {
            if let vc = currentVC as? BHBaseViewController, vc.isPresentVC {
                dismiss(animated: true)
            }
            return false
        }

        if let vc = currentVC as? BHBaseViewController {
            return vc.isCanGestureBack
        }

        return false
    }
}
