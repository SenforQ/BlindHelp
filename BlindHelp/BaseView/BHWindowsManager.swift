//
//  BHWindowsManager.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 窗口与顶层控制器工具：从 keyWindow 向下解析 `presented` / `UINavigationController` / `UITabBarController`。
final class BHWindowsManager: NSObject {

    /// 当前最前且可交互的业务控制器（已处理 Tab 选中栈与模态栈）。
    static var currentVC: UIViewController? {
        guard let keyWindow = currentWindow else { return nil }
        guard let rootVC = keyWindow.rootViewController else { return nil }

        if let presentedVC = rootVC.presentedViewController {
            if let nav = presentedVC as? UINavigationController {
                return nav.topViewController
            }
            return presentedVC
        }

        if let nav = rootVC as? UINavigationController {
            return nav.topViewController
        }

        if let tab = rootVC as? UITabBarController {
            if let nav = tab.selectedViewController as? UINavigationController {
                return nav.topViewController
            }
            return tab.viewControllers?.first
        }

        return rootVC
    }

    /// 优先返回 `UIWindowScene` 上的 keyWindow；iOS 13+ 若场景未就绪则回退到 `AppDelegate.mainWindow`。
    static var currentWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            if let key = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                return key
            }
            if let delegateWindow = (UIApplication.shared.delegate as? AppDelegate)?.mainWindow {
                return delegateWindow
            }
        }
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
}
