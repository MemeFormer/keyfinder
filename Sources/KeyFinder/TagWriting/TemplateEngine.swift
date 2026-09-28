import Foundation

struct TemplateEngine {
    func render(template: String, metadata: TrackMetadata, notationOverride: KeyNotation? = nil, options: WriteOptions) -> String {
        var output = template

        let effectiveNotation = notationOverride ?? .camelot
        let replacements: [String: String] = [
            "KeyCamelot": metadata.keyCamelot ?? "",
            "KeyOpen": metadata.keyOpen ?? "",
            "KeyTraditional": metadata.keyTraditional ?? "",
            "Key:camelot": metadata.keyCamelot ?? "",
            "Key:Camelot": metadata.keyCamelot ?? "",
            "Key:open": metadata.keyOpen ?? "",
            "Key:Open": metadata.keyOpen ?? "",
            "Key:trad": metadata.keyTraditional ?? "",
            "Key:Traditional": metadata.keyTraditional ?? "",
            "BPM": metadata.bpm.map { String(format: "%.1f", $0).replacingOccurrences(of: #"\\.0$"#, with: "", options: .regularExpression) } ?? "",
            "Energy": metadata.energy ?? "",
            "Title": metadata.title ?? "",
            "Artist": metadata.artist ?? "",
            "Album": metadata.album ?? "",
            "Year": metadata.year ?? "",
            "Filename": metadata.filename ?? "",
            "Filepath": metadata.filepath ?? "",
            "TrackNumber": metadata.trackNumber ?? "",
            "Key": metadata.key(for: effectiveNotation) ?? ""
        ]

        output = output
            .replacingOccurrences(of: "\\[", with: "__ESC_LB__")
            .replacingOccurrences(of: "\\]", with: "__ESC_RB__")

        for (token, value) in replacements {
            output = output.replacingOccurrences(of: "[\(token)]", with: value)
        }

        output = replaceCustomTokens(in: output, metadata: metadata)

        if let prefix = options.prefix { output = prefix + output }
        if let suffix = options.suffix { output += suffix }

        if options.trimWhitespace {
            output = output.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return output
            .replacingOccurrences(of: "__ESC_LB__", with: "[")
            .replacingOccurrences(of: "__ESC_RB__", with: "]")
    }

    private func replaceCustomTokens(in text: String, metadata: TrackMetadata) -> String {
        let regex = try? NSRegularExpression(pattern: #"\[Custom:([^\]]+)\]"#)
        guard let regex else { return text }
        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)

        var output = text
        for match in regex.matches(in: text, range: nsrange).reversed() {
            guard let full = Range(match.range(at: 0), in: text),
                  let nameRange = Range(match.range(at: 1), in: text) else { continue }
            let descriptor = String(text[nameRange])
            let value = metadata.customText[descriptor] ?? ""
            output.replaceSubrange(full, with: value)
        }
        return output
    }
}
