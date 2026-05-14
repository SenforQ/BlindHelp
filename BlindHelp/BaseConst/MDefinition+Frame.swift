//
//  MDefinition+Frame.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

extension UIView {

    // MARK: - Frame 便捷读写

    var x: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }

    var y: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }

    var width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }

    var height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }

    var left: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }

    var top: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }

    var right: CGFloat {
        get { frame.maxX }
        set { frame.origin.x = newValue - width }
    }

    var bottom: CGFloat {
        get { frame.maxY }
        set { frame.origin.y = newValue - height }
    }

    var centerX: CGFloat {
        get { center.x }
        set { center.x = newValue }
    }

    var centerY: CGFloat {
        get { center.y }
        set { center.y = newValue }
    }

    // MARK: - 渐变

    /// 为当前视图插入纵向渐变层（会先移除已有的 `CAGradientLayer` 子层）。
    /// - Parameters:
    ///   - topColor: 顶部颜色。
    ///   - bottomColor: 底部颜色。
    ///   - locations: 渐变停止位置，默认 `[0, 1]`。
    func addVerticalGradientBackground(
        topColor: UIColor,
        bottomColor: UIColor,
        locations: [NSNumber] = [0.0, 1.0]
    ) {
        layer.sublayers?.removeAll { $0 is CAGradientLayer }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.locations = locations
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        layer.insertSublayer(gradientLayer, at: 0)
    }
}
