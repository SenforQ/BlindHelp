//
//  UIButton+ActionBlock.swift
//  BlindHelp
//

import UIKit

/// 将 `@objc` 目标动作与闭包桥接，供 `UIButton` 关联持有。
private final class BHButtonActionTrampoline: NSObject {
    let handler: (UIButton) -> Void

    init(handler: @escaping (UIButton) -> Void) {
        self.handler = handler
    }

    @objc func invoke(_ sender: UIButton) {
        handler(sender)
    }
}

private enum BHButtonActionBlockKeys {
    static var trampoline: UInt8 = 0
}

extension UIButton {

    /// 为 `.touchUpInside` 设置点击回调；重复调用会先移除上一次绑定的闭包。
    /// - Parameter handler: 点击时执行，`sender` 为当前按钮。
    func bh_setTapAction(_ handler: @escaping (_ sender: UIButton) -> Void) {
        bh_setAction(for: .touchUpInside, handler: handler)
    }

    /// 为指定 `UIControl.Event` 设置回调；重复调用会先解除旧 trampoline 上的全部事件再绑定新回调。
    /// - Parameters:
    ///   - controlEvents: 触发的控件事件，常用 `.touchUpInside`。
    ///   - handler: 事件触发时执行，参数为当前按钮。
    func bh_setAction(for controlEvents: UIControl.Event, handler: @escaping (_ sender: UIButton) -> Void) {
        if let old = objc_getAssociatedObject(self, &BHButtonActionBlockKeys.trampoline) as? BHButtonActionTrampoline {
            removeTarget(old, action: #selector(BHButtonActionTrampoline.invoke(_:)), for: .allEvents)
        }
        let trampoline = BHButtonActionTrampoline(handler: handler)
        objc_setAssociatedObject(self, &BHButtonActionBlockKeys.trampoline, trampoline, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(trampoline, action: #selector(BHButtonActionTrampoline.invoke(_:)), for: controlEvents)
    }
}
