import Foundation

enum KeyNotation: String, Codable, CaseIterable {
    case camelot
    case open
    case traditional
}

enum ID3Version: String, Codable {
    case v23
    case v24
}

enum WriteMode: String, Codable, CaseIterable {
    case overwrite
    case prepend
    case append
    case onlyIfEmpty
}

enum TagTarget: Codable, Equatable {
    case comment(language: String = "eng", description: String = "")
    case tkey
    case grouping
    case title
    case bpm
    case artist
    case genre
    case year
    case txxx(descriptor: String)
}

struct FieldMapping: Codable, Equatable {
    var target: TagTarget
    var template: String
    var notation: KeyNotation?
    var mode: WriteMode

    static var traktorDefaults: [FieldMapping] {
        [
            FieldMapping(target: .comment(), template: "[KeyCamelot] [BPM] BPM", notation: .camelot, mode: .overwrite),
            FieldMapping(target: .tkey, template: "[KeyTraditional]", notation: .traditional, mode: .overwrite),
            FieldMapping(target: .txxx(descriptor: "MIXEDINKEY"), template: "[KeyCamelot]", notation: .camelot, mode: .overwrite)
        ]
    }
}

struct WriteOptions: Codable {
    var id3Version: ID3Version = .v23
    var trimWhitespace: Bool = true
    var prefix: String?
    var suffix: String?
    var dryRun: Bool = false
    var createBackup: Bool = true
    var forceOverwrite: Bool = false
    var mappings: [FieldMapping] = FieldMapping.traktorDefaults

    init(id3Version: ID3Version = .v23,
         trimWhitespace: Bool = true,
         prefix: String? = nil,
         suffix: String? = nil,
         dryRun: Bool = false,
         createBackup: Bool = true,
         forceOverwrite: Bool = false,
         mappings: [FieldMapping] = FieldMapping.traktorDefaults) {
        self.id3Version = id3Version
        self.trimWhitespace = trimWhitespace
        self.prefix = prefix
        self.suffix = suffix
        self.dryRun = dryRun
        self.createBackup = createBackup
        self.forceOverwrite = forceOverwrite
        self.mappings = mappings
    }
}

struct TrackMetadata: Codable, Equatable {
    var keyCamelot: String?
    var keyOpen: String?
    var keyTraditional: String?
    var bpm: Double?
    var energy: String?
    var title: String?
    var artist: String?
    var album: String?
    var year: String?
    var filename: String?
    var filepath: String?
    var trackNumber: String?

    var comment: String?
    var grouping: String?
    var tkey: String?
    var customText: [String: String] = [:]

    func key(for notation: KeyNotation) -> String? {
        switch notation {
        case .camelot: return keyCamelot
        case .open: return keyOpen
        case .traditional: return keyTraditional
        }
    }
}

struct FileWriteResult {
    let fileURL: URL
    let success: Bool
    let dryRun: Bool
    let changes: [String]
    let errors: [String]
}

protocol TagWriter {
    func readTags(fileURL: URL) throws -> TrackMetadata
    func writeTags(fileURL: URL, metadata: TrackMetadata, options: WriteOptions) -> FileWriteResult
}
