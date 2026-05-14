//
//  MDefinition+Toast.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

extension UIView {

    /// Toast_Swift 统一风格：黑底白字、圆角与阴影。
    fileprivate var toastStyle: ToastStyle {
        var style = ToastStyle()
        style.backgroundColor = UIColor.black
        style.messageColor = UIColor.white
        style.messageFont = .systemFont(ofSize: 12)
        style.cornerRadius = 5
        style.shadowColor = UIColor.lightGray
        style.shadowOffset = CGSize(width: 5, height: 4)
        style.displayShadow = true
        style.titleAlignment = .center
        style.titleColor = UIColor.white
        style.titleFont = .boldSystemFont(ofSize: 14)
        style.imageSize = CGSize(width: 20, height: 20)
        return style
    }

    /// 在中央显示加载中菊花（Toast 活动指示器）。
    func cd_showActivity() {
        ToastManager.shared.style.activitySize = CGSize(width: 65, height: 65)
        ToastManager.shared.style.activityBackgroundColor = UIColor.black
        self.makeToastActivity(.center)
    }

    /// 短时文字提示，默认约 2 秒。
    func cd_showDefaultToast(_ msg: String) {
        self.cd_showToast(msg, duration: 2, position: .center, style: toastStyle)
    }

    /// 需手动关闭的长驻提示（内部用极大 duration 实现）。
    func cd_showKeepToast(_ msg: String) {
        self.cd_showToast(msg, duration: TimeInterval(NSIntegerMax), position: .center, style: toastStyle)
    }

    /// 自定义停留时长。
    func cd_showDurationToast(_ msg: String, duration: Double) {
        self.cd_showToast(msg, duration: duration, position: .center, style: toastStyle)
    }

    private func cd_showToast(_ msg: String, duration: TimeInterval, position: ToastPosition, style: ToastStyle) {
        self.cd_hidToast()
        self.makeToast(msg, duration: duration, position: position, title: nil, image: nil, style: toastStyle, completion: nil)
    }

    /// 隐藏所有 Toast 与活动指示器并清空队列。
    func cd_hidToast() {
        self.hideAllToasts(includeActivity: true, clearQueue: true)
    }
}
