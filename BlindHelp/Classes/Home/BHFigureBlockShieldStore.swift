//
//  BHFigureBlockShieldStore.swift
//  BlindHelp
//

import Foundation

extension Notification.Name {

    /// 拉黑或屏蔽角色后发出，首页应重新加载并过滤对应 `figureId`。
    static let bhHomeFigureBlockedOrShieldedListDidChange = Notification.Name(
        "bhHomeFigureBlockedOrShieldedListDidChange"
    )
}

/// 拉黑、屏蔽：`figureId` 与首页「旅行视频」「热门地点」数据源关联；二者均不参与首页列表展示；并同步取消对该角色的本地「关注」。
enum BHFigureBlockShieldStore {

    private static let blockedKey = "BHFigureBlocked.ids.v1"
    private static let shieldedKey = "BHFigureShield.ids.v1"

    private static func readIds(key: String) -> Set<Int> {
        let arr = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        return Set(arr)
    }

    private static func writeIds(key: String, _ set: Set<Int>) {
        UserDefaults.standard.set(Array(set.sorted()), forKey: key)
    }

    static func blockedFigureIds() -> Set<Int> {
        readIds(key: blockedKey)
    }

    static func shieldedFigureIds() -> Set<Int> {
        readIds(key: shieldedKey)
    }

    static func block(figureId: Int) {
        var blocked = readIds(key: blockedKey)
        blocked.insert(figureId)
        writeIds(key: blockedKey, blocked)
        var shielded = readIds(key: shieldedKey)
        shielded.remove(figureId)
        writeIds(key: shieldedKey, shielded)
        BHVideoFigureFollowStore.setFollowing(false, figureId: figureId)
    }

    static func shield(figureId: Int) {
        var shielded = readIds(key: shieldedKey)
        shielded.insert(figureId)
        writeIds(key: shieldedKey, shielded)
        var blocked = readIds(key: blockedKey)
        blocked.remove(figureId)
        writeIds(key: blockedKey, blocked)
        BHVideoFigureFollowStore.setFollowing(false, figureId: figureId)
    }

    static func shouldHideFromHomeFeed(figureId: Int) -> Bool {
        blockedFigureIds().contains(figureId) || shieldedFigureIds().contains(figureId)
    }
}
