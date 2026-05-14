//
//  MDefinition+Font.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

extension UIFont {

    /// 苹方字重。粗体在系统层面一般用 `PingFangSC-Semibold`（无单独 `Bold` PostScript 名时与之对应）。
    enum BHPingFangWeight {
        /// 普通 — Regular
        case regular
        /// 中黑 — Medium
        case medium
        /// 粗体 — Semibold（视觉上的 Bold）
        case bold
    }

    /// 优先使用 **PingFang SC** 对应字重；若不可用则依次尝试 PingFang **TC / HK** 同字重，最后使用系统 **San Francisco** 近似字重。
    static func bh_pingFang(size: CGFloat, weight: BHPingFangWeight = .regular) -> UIFont {
        let candidates: [String]
        switch weight {
        case .regular:
            candidates = [
                "PingFangSC-Regular",
                "PingFangTC-Regular",
                "PingFangHK-Regular",
            ]
        case .medium:
            candidates = [
                "PingFangSC-Medium",
                "PingFangTC-Medium",
                "PingFangHK-Medium",
            ]
        case .bold:
            candidates = [
                "PingFangSC-Semibold",
                "PingFangTC-Semibold",
                "PingFangHK-Semibold",
                "PingFangSC-Medium",
                "PingFangTC-Medium",
                "PingFangHK-Medium",
            ]
        }

        for postScriptName in candidates {
            if let font = UIFont(name: postScriptName, size: size) {
                return font
            }
        }

        let systemWeight: UIFont.Weight
        switch weight {
        case .regular:
            systemWeight = .regular
        case .medium:
            systemWeight = .medium
        case .bold:
            systemWeight = .semibold
        }
        return .systemFont(ofSize: size, weight: systemWeight)
    }
}

/// 按逻辑像素字号取苹方字体（与 `UIFont.bh_pingFang` 相同语义，便于全局调用）。
func kFontPingFang(_ size: CGFloat, weight: UIFont.BHPingFangWeight = .regular) -> UIFont {
    UIFont.bh_pingFang(size: size, weight: weight)
}

/// 设计稿宽度 375 基准下的缩放字号 + 苹方（与 `kScaleW` 搭配）。
func kFontPingFangScaled(_ designPointSize: CGFloat, weight: UIFont.BHPingFangWeight = .regular) -> UIFont {
    UIFont.bh_pingFang(size: kScaleW(designPointSize), weight: weight)
}
