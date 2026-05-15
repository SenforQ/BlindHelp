//
//  BHFigureChatHistoryStore.swift
//  BlindHelp
//

import UIKit

/// 与各角色私信的「只可发一条」本地存储；供 `BHFigureMessageViewController` 与会话列表共用。
enum BHFigureChatHistoryStore {

    private static func sentKey(_ figureId: Int) -> String {
        "BHFigure.Chat.UserSentOnce.v1.\(figureId)"
    }

    private static func bodyKey(_ figureId: Int) -> String {
        "BHFigure.Chat.UserMessageBody.v1.\(figureId)"
    }

    private static func timestampKey(_ figureId: Int) -> String {
        "BHFigure.Chat.UserSentAt.v1.\(figureId)"
    }

    static func hasSent(for figureId: Int) -> Bool {
        UserDefaults.standard.bool(forKey: sentKey(figureId))
    }

    static func savedMessageBody(for figureId: Int) -> String? {
        guard hasSent(for: figureId) else { return nil }
        return UserDefaults.standard.string(forKey: bodyKey(figureId))
    }

    /// 最近一次发送私信的时间戳（用户点击「发送」的时刻）。旧版仅写过正文未写时间的，会在首次读取时补记为当前时刻。
    static func lastSentTimestamp(for figureId: Int) -> TimeInterval {
        guard hasSent(for: figureId) else { return 0 }
        let k = timestampKey(figureId)
        var v = UserDefaults.standard.double(forKey: k)
        if v <= 0 {
            v = Date().timeIntervalSince1970
            UserDefaults.standard.set(v, forKey: k)
        }
        return v
    }

    static func persistSend(figureId: Int, body: String) {
        UserDefaults.standard.set(true, forKey: sentKey(figureId))
        UserDefaults.standard.set(body, forKey: bodyKey(figureId))
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey(figureId))
    }

    /// 已发送过私信的角色 `figureId`，按最近发送时间从新到旧；不含拉黑/屏蔽角色。
    static func sortedMessagedFigureIdsRecentFirst() -> [Int] {
        let ids = BHFigureResourceCatalog.allProfiles.map(\.figureId).filter { fid in
            !BHFigureBlockShieldStore.shouldHideFromHomeFeed(figureId: fid) && hasSent(for: fid)
        }
        return ids.sorted { a, b in
            lastSentTimestamp(for: a) > lastSentTimestamp(for: b)
        }
    }
}

/// 旅行助手会话里用户自行发送的最新一条（可多次发送）；消息列表右侧时间取此时间。
enum BHTravelAssistantOutboundStore {

    private static let tsKey = "BHTravelAssistant.lastOutboundUnix.v1"

    private static let bodyKey = "BHTravelAssistant.lastOutboundBody.v1"

    static func lastOutboundUnix() -> TimeInterval {
        UserDefaults.standard.double(forKey: tsKey)
    }

    static func lastOutboundBody() -> String? {
        guard lastOutboundUnix() > 0 else { return nil }
        return UserDefaults.standard.string(forKey: bodyKey)
    }

    static func recordOutbound(trimmedBody: String) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tsKey)
        UserDefaults.standard.set(trimmedBody, forKey: bodyKey)
    }
}
