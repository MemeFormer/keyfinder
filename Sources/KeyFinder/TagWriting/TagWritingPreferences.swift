import Foundation

enum TagWritingProfileID: String, CaseIterable, Identifiable, Codable {
    case conservativeKeyOnly
    case overwriteKeyAndBPM
    case dualKeyTraktor
    case titlePrefixSort

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .conservativeKeyOnly: return "Conservative (Key only)"
        case .overwriteKeyAndBPM: return "Overwrite Key + BPM"
        case .dualKeyTraktor: return "Dual-Key Traktor"
        case .titlePrefixSort: return "Title Prefix Sort"
        }
    }
}

struct TagWritingPreferences: Codable {
    var profile: TagWritingProfileID = .dualKeyTraktor
    var mappings: [FieldMapping] = TagWritingPreferences.profileMappings(.dualKeyTraktor)
    var forceOverwrite = false
    var createBackup = true
    var dryRunOnly = false
    var maxConcurrentWrites = 2

    static func profileMappings(_ profile: TagWritingProfileID) -> [FieldMapping] {
        switch profile {
        case .conservativeKeyOnly:
            return [
                FieldMapping(target: .tkey, template: "[KeyTraditional]", notation: .traditional, mode: .onlyIfEmpty)
            ]
        case .overwriteKeyAndBPM:
            return [
                FieldMapping(target: .tkey, template: "[KeyTraditional]", notation: .traditional, mode: .overwrite),
                FieldMapping(target: .bpm, template: "[BPM]", notation: nil, mode: .overwrite)
            ]
        case .dualKeyTraktor:
            return [
                FieldMapping(target: .comment(), template: "[KeyCamelot] - [Energy]", notation: .camelot, mode: .overwrite),
                FieldMapping(target: .txxx(descriptor: "KEYFINDER_KEY"), template: "[KeyTraditional]", notation: .traditional, mode: .overwrite),
                FieldMapping(target: .txxx(descriptor: "MIXEDINKEY"), template: "[KeyCamelot]", notation: .camelot, mode: .overwrite)
            ]
        case .titlePrefixSort:
            return [
                FieldMapping(target: .title, template: "[KeyCamelot] - [BPM] - [Title]", notation: .camelot, mode: .overwrite),
                FieldMapping(target: .comment(), template: "[KeyTraditional] [BPM]", notation: .traditional, mode: .overwrite)
            ]
        }
    }
}
