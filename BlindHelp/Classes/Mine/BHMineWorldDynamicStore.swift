//
//  BHMineWorldDynamicStore.swift
//  BlindHelp
//

import Foundation
import UIKit

extension Notification.Name {
    /// 「我的世界」动态列表本地缓存变更（发布成功后发送）。
    static let bhMineWorldDynamicsDidUpdate = Notification.Name("BHMineWorldDynamicsDidUpdate")
}

struct BHMineWorldDynamicRecord: Codable, Equatable {

    let id: String
    let text: String
    let imageFileNames: [String]
    let createdAt: TimeInterval
}

final class BHMineWorldDynamicStore {

    static let shared = BHMineWorldDynamicStore()

    private let udKey = "BHMineWorldDynamics.records.v1"
    private init() {}

    private var dynamicsDirectoryURL: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return doc.appendingPathComponent("BHMineWorldDynamics", isDirectory: true)
    }

    private var dynamicsImagesDirectoryURL: URL {
        dynamicsDirectoryURL.appendingPathComponent("images", isDirectory: true)
    }

    func allRecordsNewestFirst() -> [BHMineWorldDynamicRecord] {
        let raw = (UserDefaults.standard.array(forKey: udKey) as? [Data]) ?? []
        let decoded = raw.compactMap { Self.decodeRecord($0) }
        return decoded.sorted { $0.createdAt > $1.createdAt }
    }

    func imageFileURL(for fileName: String) -> URL {
        dynamicsImagesDirectoryURL.appendingPathComponent(fileName)
    }

    @discardableResult
    func append(text rawText: String, images: [UIImage]) -> Bool {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imgs = Array(images.prefix(3))
        guard !trimmed.isEmpty || !imgs.isEmpty else { return false }

        try? FileManager.default.createDirectory(at: dynamicsImagesDirectoryURL, withIntermediateDirectories: true)

        var names: [String] = []
        for img in imgs {
            let name = "\(UUID().uuidString).jpg"
            let url = dynamicsImagesDirectoryURL.appendingPathComponent(name)
            if let data = img.jpegData(compressionQuality: 0.85) {
                do {
                    try data.write(to: url, options: .atomic)
                    names.append(name)
                } catch { }
            }
        }

        let rec = BHMineWorldDynamicRecord(
            id: UUID().uuidString,
            text: trimmed,
            imageFileNames: names,
            createdAt: Date().timeIntervalSince1970
        )

        var list = allRecordsNewestFirst()
        list.insert(rec, at: 0)
        persist(list)
        NotificationCenter.default.post(name: .bhMineWorldDynamicsDidUpdate, object: nil)
        return true
    }

    private func persist(_ list: [BHMineWorldDynamicRecord]) {
        let encoded = list.compactMap(Self.encodeRecord)
        UserDefaults.standard.set(encoded, forKey: udKey)
    }

    private static func decodeRecord(_ data: Data) -> BHMineWorldDynamicRecord? {
        try? JSONDecoder().decode(BHMineWorldDynamicRecord.self, from: data)
    }

    private static func encodeRecord(_ r: BHMineWorldDynamicRecord) -> Data? {
        try? JSONEncoder().encode(r)
    }
}
