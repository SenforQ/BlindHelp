//
//  BHChinaRegionModels.swift
//  BlindHelp
//

import Foundation

/// 提供给 UI 展示的「省 → 下辖市（或区等）名称」快照。
struct BHProvinceSnapshot {
    let provinceName: String
    /// 地级市 / 县区 / 香港澳门台湾二级名称等。
    let cityNames: [String]
}

enum BHChinaRegionLoader {

    private struct PCNodeDTO: Codable {
        let code: String
        let name: String
        let children: [PCCityDTO]
    }

    private struct PCCityDTO: Codable {
        let code: String
        let name: String
    }

    /// 解码 `pc-code.json` 与 `pc-supplement.json` 后合并的顺序列表。
    static let provincesSnapshot: [BHProvinceSnapshot] = {
        decodeBundleArray(name: "pc-code") + decodeBundleArray(name: "pc-supplement")
    }()

    private static func decodeBundleArray(name: String) -> [BHProvinceSnapshot] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("⚠️ missing \(name).json in bundle")
            return []
        }
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let list = try? JSONDecoder().decode([PCNodeDTO].self, from: data) else { return [] }
        return list.map {
            BHProvinceSnapshot(provinceName: $0.name, cityNames: $0.children.map(\.name))
        }
    }
}
