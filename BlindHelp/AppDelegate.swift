//
//  AppDelegate.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/12.
//

import UIKit

/// 应用进程级入口；窗口与根界面由 `SceneDelegate` 在 `UIWindowScene` 就绪后创建。
/// `mainWindow` 仍赋值给此处，便于沿用 `BHWindowsManager` 等对 AppDelegate 的回退读取。
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// 当前主窗口（由 `SceneDelegate` 在连接场景时赋值）。
    var mainWindow: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        self.mainWindow = window

        let tabBarController = BHBaseTabBarControllerManager.shared.tabBarController
        tabBarController.createChildViewControllersIfNeeded()
        tabBarController.selectedIndex = 0
        tabBarController.hidesBottomBarWhenPushed = true
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        return true
    }
    
}
