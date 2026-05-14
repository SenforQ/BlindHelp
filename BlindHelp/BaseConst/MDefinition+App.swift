//
//  MDefinition+App.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

/// 应用版本号（CFBundleShortVersionString）。
let kAppVersion: String = {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
}()

/// Build 号（CFBundleVersion）。
let kAppBuildNumber: String = {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}()

/// 显示名称（CFBundleDisplayName），缺失时回退为 `BlindHelp`。
let kAppName: String = {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "BlindHelp"
}()

/// 当前 keyWindow；优先多场景 API，低版本用 `keyWindow`。
var kAppCurrentWindow: UIWindow? {
    if #available(iOS 13.0, *) {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    } else {
        return UIApplication.shared.keyWindow
    }
}
