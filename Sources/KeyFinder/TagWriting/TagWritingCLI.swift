import Foundation

struct TagWritingCLI {
    struct ParsedArguments {
        var writeTags = false
        var dryRun = false
        var template: String?
        var field: String?
        var mode: WriteMode = .overwrite
        var backupPath: String?
    }

    static func parse(arguments: [String]) -> ParsedArguments {
        var parsed = ParsedArguments()
        var iterator = arguments.makeIterator()

        while let arg = iterator.next() {
            switch arg {
            case "--write-tags": parsed.writeTags = true
            case "--dry-run": parsed.dryRun = true
            case "--template": parsed.template = iterator.next()
            case "--field": parsed.field = iterator.next()
            case "--mode":
                if let raw = iterator.next(), let mode = WriteMode(rawValue: raw) {
                    parsed.mode = mode
                }
            case "--backup-path": parsed.backupPath = iterator.next()
            default: continue
            }
        }

        return parsed
    }
}
