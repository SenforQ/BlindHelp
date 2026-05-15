//
//  BHVideoFigureFollowStore.swift
//  BlindHelp
//

import Foundation

enum BHVideoFigureFollowStore {
    private static let key = "BHVideoFigureFollow.ids.v1"

    private static func readIds() -> Set<Int> {
        let arr = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        return Set(arr)
    }

    static func isFollowing(_ figureId: Int) -> Bool {
        readIds().contains(figureId)
    }

    static func setFollowing(_ following: Bool, figureId: Int) {
        var s = readIds()
        if following {
            s.insert(figureId)
        } else {
            s.remove(figureId)
        }
        UserDefaults.standard.set(Array(s.sorted()), forKey: key)
    }

    /// 已关注角色的 `figureId` 列表（升序，用于「关注」流等）。
    static func sortedFollowedFigureIds() -> [Int] {
        Array(readIds()).sorted()
    }
}
