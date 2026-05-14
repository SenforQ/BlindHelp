//
//  BHUserProfileManager.swift
//  BlindHelp
//

import UIKit
import DefaultsKit

/// 本地持久化的用户资料（不含二进制头像，头像单独存文件）。
struct BHStoredUserProfile: Codable, Equatable {

    /// 昵称
    var nickname: String
    /// 性格文案
    var personality: String
    /// 与编辑页爱好按钮顺序对应：0 = 旅行
    var hobbyIndex: Int
    /// 地区展示文案（如「太空」「广东省 广州市」）
    var regionDisplay: String
    /// 签名，可为空字符串
    var signature: String
    /// `true` 使用资源图 `BHUserProfileManager.defaultAvatarAssetName`；`false` 时使用本地头像文件。
    var usesDefaultAvatar: Bool

    static let baseline = BHStoredUserProfile(
        nickname: "觅兔游",
        personality: "乐观",
        hobbyIndex: 0,
        regionDisplay: "太空",
        signature: "",
        usesDefaultAvatar: true
    )
}

extension Notification.Name {
    /// 调用方保存成功后发送，便于「我的」等页刷新。
    static let bhUserProfileDidUpdate = Notification.Name("BHUserProfileDidUpdate")
}

/// 管理用户资料的读取、写入与默认头像资源名。
final class BHUserProfileManager {

    static let shared = BHUserProfileManager()

    static let defaultAvatarAssetName = "applogo"

    static let hobbyTitles = ["旅行", "徒步", "运动", "看书", "音乐"]

    private let profileKey = Key<BHStoredUserProfile>("BHStoredUserProfile.v1")
    private let defaults = Defaults.shared

    private init() {}

    private var avatarDirectoryURL: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return doc.appendingPathComponent("BHUserProfile", isDirectory: true)
    }

    private var customAvatarFileURL: URL {
        avatarDirectoryURL.appendingPathComponent("avatar.jpg")
    }

    /// 若无持久化数据则返回内置默认值组成的快照。
    func currentProfileSnapshot() -> BHStoredUserProfile {
        defaults.get(for: profileKey).map(Self.normalize(_:)) ?? .baseline
    }

    /// 将资料写入 UserDefaults；根据 `snapshot.usesDefaultAvatar` 更新或删除本地头像文件。`avatarImage` 仅在非默认头像时必须传入。
    func save(snapshot raw: BHStoredUserProfile, avatarImage: UIImage?) {
        let snapshot = Self.normalize(raw)
        if snapshot.usesDefaultAvatar {
            try? FileManager.default.removeItem(at: customAvatarFileURL)
        } else if let avatarImage {
            try? FileManager.default.createDirectory(at: avatarDirectoryURL, withIntermediateDirectories: true)
            if let data = avatarImage.jpegData(compressionQuality: 0.9) {
                try? data.write(to: customAvatarFileURL, options: .atomic)
            }
        }
        defaults.set(snapshot, for: profileKey)
        NotificationCenter.default.post(name: .bhUserProfileDidUpdate, object: nil)
    }

    func loadAvatarForDisplay() -> UIImage? {
        let snap = currentProfileSnapshot()
        if snap.usesDefaultAvatar {
            return UIImage(named: Self.defaultAvatarAssetName)
        }
        guard let data = try? Data(contentsOf: customAvatarFileURL),
              let img = UIImage(data: data)
        else {
            return UIImage(named: Self.defaultAvatarAssetName)
        }
        return img
    }

    private static func normalize(_ p: BHStoredUserProfile) -> BHStoredUserProfile {
        var o = p
        let maxI = max(Self.hobbyTitles.count - 1, 0)
        o.hobbyIndex = min(max(0, o.hobbyIndex), maxI)
        return o
    }
}
