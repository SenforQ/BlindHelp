//
//  MDefinition+Color.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import UIKit

extension UIColor {

    // MARK: - 十六进制颜色

    /// 用十六进制字符串创建颜色；支持 `#RRGGBB`、`0xRRGGBB`、`RRGGBB`，解析失败时返回红色便于发现问题。
    /// - Parameters:
    ///   - hexString: 色值字符串。
    ///   - alpha: 透明度，默认 1。
    /// - Returns: 对应 `UIColor`。
    static func kHexColor(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        let cleanedHex = cleanHexString(hexString)

        guard isValidHexString(cleanedHex) else {
            print("⚠️ Invalid hex color string: \(hexString)")
            return .red
        }

        let rgbValues = parseHexToRGB(cleanedHex)
        return UIColor(
            red: rgbValues.red / 255.0,
            green: rgbValues.green / 255.0,
            blue: rgbValues.blue / 255.0,
            alpha: alpha
        )
    }

    // MARK: - Private

    private static func cleanHexString(_ hexString: String) -> String {
        return hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "0X", with: "")
    }

    private static func isValidHexString(_ hexString: String) -> Bool {
        guard hexString.count == 6 else { return false }
        return hexString.allSatisfy { $0.isHexDigit }
    }

    private static func parseHexToRGB(_ hexString: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let startIndex = hexString.startIndex

        let redStart = startIndex
        let redEnd = hexString.index(startIndex, offsetBy: 2)
        let redString = String(hexString[redStart..<redEnd])

        let greenStart = redEnd
        let greenEnd = hexString.index(greenStart, offsetBy: 2)
        let greenString = String(hexString[greenStart..<greenEnd])

        let blueStart = greenEnd
        let blueEnd = hexString.index(blueStart, offsetBy: 2)
        let blueString = String(hexString[blueStart..<blueEnd])

        let red = CGFloat(Int(redString, radix: 16) ?? 0)
        let green = CGFloat(Int(greenString, radix: 16) ?? 0)
        let blue = CGFloat(Int(blueString, radix: 16) ?? 0)

        return (red: red, green: green, blue: blue)
    }
}
