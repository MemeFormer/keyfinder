import Foundation

struct TagWriteBatchSummary {
    let batchID: UUID
    let results: [FileWriteResult]

    var failures: [FileWriteResult] { results.filter { !$0.success } }
    var successes: [FileWriteResult] { results.filter { $0.success } }
}

final class TagWriteBatchService {
    private let writer: TagWriter
    private let backupStore: TagBackupStore

    init(writer: TagWriter = ID3TagWriter(), backupStore: TagBackupStore = TagBackupStore()) {
        self.writer = writer
        self.backupStore = backupStore
    }

    func writeBatch(fileURLs: [URL], metadataByURL: [URL: TrackMetadata], options: WriteOptions, maxConcurrentWrites: Int = 2) -> TagWriteBatchSummary {
        let batchID = UUID()
        var backupEntries: [TagBackupEntry] = []

        if options.createBackup {
            for url in fileURLs {
                if let original = try? writer.readTags(fileURL: url) {
                    backupEntries.append(TagBackupEntry(id: batchID, timestamp: Date(), filePath: url.path, metadata: original))
                }
            }
            try? backupStore.save(entries: backupEntries)
        }

        let semaphore = DispatchSemaphore(value: maxConcurrentWrites)
        let lock = NSLock()
        var results: [FileWriteResult] = []

        DispatchQueue.concurrentPerform(iterations: fileURLs.count) { idx in
            let url = fileURLs[idx]
            semaphore.wait()
            defer { semaphore.signal() }

            let requested = metadataByURL[url] ?? TrackMetadata(filename: url.lastPathComponent, filepath: url.path)
            let existing = (try? writer.readTags(fileURL: url)) ?? TrackMetadata(filename: url.lastPathComponent, filepath: url.path)
            let metadata = merge(existing: existing, requested: requested)
            let result = writer.writeTags(fileURL: url, metadata: metadata, options: options)

            lock.lock()
            results.append(result)
            lock.unlock()
        }

        return TagWriteBatchSummary(batchID: batchID, results: results)
    }

    func undo(batchID: UUID) -> [FileWriteResult] {
        backupStore.undo(batchID: batchID, writer: writer)
    }

    func traktorVerification(for url: URL) -> [String: String] {
        let metadata = try? writer.readTags(fileURL: url)
        return [
            "COMM": metadata?.comment ?? "",
            "TKEY": metadata?.tkey ?? "",
            "MIXEDINKEY": metadata?.customText["MIXEDINKEY"] ?? "",
            "INITIALKEY": metadata?.customText["INITIALKEY"] ?? "",
            "TIT1": metadata?.grouping ?? ""
        ]
    }
}


private func merge(existing: TrackMetadata, requested: TrackMetadata) -> TrackMetadata {
    TrackMetadata(
        keyCamelot: requested.keyCamelot ?? existing.keyCamelot,
        keyOpen: requested.keyOpen ?? existing.keyOpen,
        keyTraditional: requested.keyTraditional ?? existing.keyTraditional,
        bpm: requested.bpm ?? existing.bpm,
        energy: requested.energy ?? existing.energy,
        title: requested.title ?? existing.title,
        artist: requested.artist ?? existing.artist,
        album: requested.album ?? existing.album,
        year: requested.year ?? existing.year,
        filename: requested.filename ?? existing.filename,
        filepath: requested.filepath ?? existing.filepath,
        trackNumber: requested.trackNumber ?? existing.trackNumber,
        comment: requested.comment ?? existing.comment,
        grouping: requested.grouping ?? existing.grouping,
        tkey: requested.tkey ?? existing.tkey,
        customText: existing.customText.merging(requested.customText) { _, new in new }
    )
}
