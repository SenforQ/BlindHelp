//
//  MDefinition+System.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 状态栏高度（通过当前 `UIWindowScene` 的 `statusBarManager` 读取）。
let kStatusBarHeight: CGFloat = {
    if #available(iOS 13.0, *) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let statusBarManager = windowScene.statusBarManager {
            return statusBarManager.statusBarFrame.height
        }
    } else {
        return UIApplication.shared.statusBarFrame.height
    }
    return 0
}()

/// 底部安全区高度（全面屏 Home Indicator 区域）。
let kBottomSafeHeight: CGFloat = {
    if #available(iOS 11.0, *) {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.safeAreaInsets.bottom
            }
        } else {
            return UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        }
        return 0
    }
    return getSafeAreaBottomForOlderVersions()
}()

/// iOS 11 以下且无 `safeAreaInsets` 时的底部占位估算。
private func getSafeAreaBottomForOlderVersions() -> CGFloat {
    if UIDevice.current.userInterfaceIdiom == .phone {
        let screenSize = UIScreen.main.bounds.size
        let isNotchedDevice = screenSize.height >= 812 && screenSize.width >= 375
        return isNotchedDevice ? 34.0 : 0.0
    }
    return 0.0
}

/// 导航栏内容区高度（不含状态栏），按设计稿宽度 375 缩放。
let kNavBarHeight: CGFloat = kScaleW(44)

/// 自定义导航栏总高度：状态栏 + 导航内容区。
let kNavBarFullHeight: CGFloat = kNavBarHeight + kStatusBarHeight

/// 系统 TabBar 标准高度（通过临时 `UITabBar` `sizeToFit` 获取）。
let kTabBarHeight: CGFloat = {
    let tempTabBar = UITabBar()
    tempTabBar.sizeToFit()
    return tempTabBar.frame.height
}()

/// TabBar 占位总高度：条高度 + 底部安全区。
let kTabBarFullHeight: CGFloat = kTabBarHeight + kBottomSafeHeight

/// 屏幕逻辑宽度。
let kScreenWidth: CGFloat = UIScreen.main.bounds.width

/// 屏幕逻辑高度。
let kScreenHeight: CGFloat = UIScreen.main.bounds.height

/// 按设计稿宽度等比缩放横向尺寸（默认基准宽 375，向下取整）。
func kScaleW(_ num: CGFloat, originW: CGFloat = 375.0) -> CGFloat {
    return floor(UIScreen.main.bounds.width / originW * num)
}

/// 按设计稿高度等比缩放纵向尺寸（默认基准高 812，向下取整）。
func kScaleH(_ num: CGFloat, originH: CGFloat = 812.0) -> CGFloat {
    return floor(UIScreen.main.bounds.height / originH * num)
}
