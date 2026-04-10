import Foundation

struct TagBackupEntry: Codable {
    let id: UUID
    let timestamp: Date
    let filePath: String
    let metadata: TrackMetadata
}

final class TagBackupStore {
    private let fileURL: URL

    init(fileURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/keyfinder", isDirectory: true)
        .appendingPathComponent("keyfinder_tag_backup.json")) {
        self.fileURL = fileURL
    }

    func save(entries: [TagBackupEntry]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let existing = (try? load()) ?? []
        let merged = existing + entries
        let data = try JSONEncoder().encode(merged)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [TagBackupEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([TagBackupEntry].self, from: data)
    }

    func undo(batchID: UUID, writer: TagWriter) -> [FileWriteResult] {
        let entries = (try? load())?.filter { $0.id == batchID } ?? []
        return entries.map { entry in
            writer.writeTags(fileURL: URL(fileURLWithPath: entry.filePath), metadata: entry.metadata, options: WriteOptions(forceOverwrite: true))
        }
    }
}
