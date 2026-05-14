//
//  BHLocalMineAlbumStore.swift
//  BlindHelp
//

import Foundation

struct BHMineSavedMediaRecord: Codable, Equatable, Hashable {

    enum Kind: String, Codable {
        case photo
        case video
    }

    let id: UUID
    let kind: Kind
    let storedFileName: String
    let createdAt: TimeInterval

    func fileURL(storeRoot root: URL) -> URL {
        let sub = kind == .photo ? "photos" : "videos"
        return root.appendingPathComponent(sub, isDirectory: true).appendingPathComponent(storedFileName, isDirectory: false)
    }
}

private struct BHMineAlbumManifest: Codable {
    struct Row: Codable {
        let id: UUID
        let kindRaw: String
        let storedFileName: String
        let createdAt: TimeInterval
    }

    var items: [Row]
}

final class BHLocalMineAlbumStore {

    static let shared = BHLocalMineAlbumStore()

    private(set) var records: [BHMineSavedMediaRecord] = []

    private var manifestURL: URL {
        sandboxRootURL.appendingPathComponent("manifest.json", isDirectory: false)
    }

    private var sandboxRootURL: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return doc.appendingPathComponent("BHMineUserAlbum", isDirectory: true)
    }

    private init() {
        try? FileManager.default.createDirectory(at: sandboxRootURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: sandboxRootURL.appendingPathComponent("photos", isDirectory: true), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: sandboxRootURL.appendingPathComponent("videos", isDirectory: true), withIntermediateDirectories: true)
        loadManifestIfNeededSync()
    }

    func filteredRecords(kind: BHMineSavedMediaRecord.Kind) -> [BHMineSavedMediaRecord] {
        records.filter { $0.kind == kind }.sorted { $0.createdAt > $1.createdAt }
    }

    func addPhotoJPEGData(_ data: Data) throws -> BHMineSavedMediaRecord {
        let id = UUID()
        let name = "\(id.uuidString).jpg"
        let dest = sandboxRootURL.appendingPathComponent("photos", isDirectory: true).appendingPathComponent(name)
        try data.write(to: dest, options: .atomic)
        let row = BHMineSavedMediaRecord(id: id, kind: .photo, storedFileName: name, createdAt: Date().timeIntervalSince1970)
        records.append(row)
        saveManifestSync()
        return row
    }

    func addVideoCopiedFromPickerURL(_ pickerURL: URL) throws -> BHMineSavedMediaRecord {
        let id = UUID()
        let srcExt = pickerURL.pathExtension.lowercased()
        let ext = srcExt.isEmpty ? "mov" : srcExt
        let name = "\(id.uuidString).\(ext)"
        let dest = sandboxRootURL.appendingPathComponent("videos", isDirectory: true).appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: pickerURL, to: dest)
        let row = BHMineSavedMediaRecord(id: id, kind: .video, storedFileName: name, createdAt: Date().timeIntervalSince1970)
        records.append(row)
        saveManifestSync()
        return row
    }

    func deleteRecord(id: UUID) {
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        let row = records[idx]
        let url = row.fileURL(storeRoot: sandboxRootURL)
        try? FileManager.default.removeItem(at: url)
        records.remove(at: idx)
        saveManifestSync()
    }

    func resolvedURL(for row: BHMineSavedMediaRecord) -> URL {
        row.fileURL(storeRoot: sandboxRootURL)
    }

    func fileExists(for row: BHMineSavedMediaRecord) -> Bool {
        FileManager.default.fileExists(atPath: row.fileURL(storeRoot: sandboxRootURL).path)
    }

    private func loadManifestIfNeededSync() {
        guard let data = try? Data(contentsOf: manifestURL) else {
            records = []
            return
        }
        guard let decoded = try? JSONDecoder().decode(BHMineAlbumManifest.self, from: data) else {
            records = []
            return
        }
        records = decoded.items.compactMap { r in
            guard let kind = BHMineSavedMediaRecord.Kind(rawValue: r.kindRaw) else { return nil }
            return BHMineSavedMediaRecord(id: r.id, kind: kind, storedFileName: r.storedFileName, createdAt: r.createdAt)
        }
    }

    private func saveManifestSync() {
        let rows = records.map {
            BHMineAlbumManifest.Row(
                id: $0.id,
                kindRaw: $0.kind.rawValue,
                storedFileName: $0.storedFileName,
                createdAt: $0.createdAt
            )
        }
        let wrapped = BHMineAlbumManifest(items: rows)
        guard let data = try? JSONEncoder().encode(wrapped) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }
}
