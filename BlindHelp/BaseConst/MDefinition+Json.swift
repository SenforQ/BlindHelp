//
//  MDefinition+Json.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import Foundation

/// 将网络返回的 `Data` 反序列化为字典；根节点为数组或其它类型时返回空字典。
/// - Parameter valueData: 原始 JSON 数据。
/// - Returns: `[String: Any]`，解析失败或无字典根节点时为 `[:]`。
func kNetworkingSetupDataToJson(_ valueData: Data) -> [String: Any] {
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: valueData, options: [])
        if let jsonDictionary = jsonObject as? [String: Any] {
            return jsonDictionary
        } else if jsonObject is [Any] {
            return [:]
        } else {
            return [:]
        }
    } catch {
        print("Failed to decode JSON: \(error.localizedDescription)")
        return [:]
    }
}
