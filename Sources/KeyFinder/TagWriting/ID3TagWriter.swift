import Foundation

final class ID3TagWriter: TagWriter {
    private let templateEngine = TemplateEngine()

    func readTags(fileURL: URL) throws -> TrackMetadata {
        let data = try Data(contentsOf: fileURL)
        let parsed = parseID3v2(data: data)

        var metadata = TrackMetadata()
        metadata.filename = fileURL.lastPathComponent
        metadata.filepath = fileURL.path
        metadata.title = parsed.textFrames["TIT2"]
        metadata.artist = parsed.textFrames["TPE1"]
        metadata.album = parsed.textFrames["TALB"]
        metadata.year = parsed.textFrames["TYER"] ?? parsed.textFrames["TDRC"]
        metadata.trackNumber = parsed.textFrames["TRCK"]
        metadata.comment = parsed.comment
        metadata.grouping = parsed.textFrames["TIT1"]
        metadata.tkey = parsed.textFrames["TKEY"]
        metadata.customText = parsed.txxx
        return metadata
    }

    func writeTags(fileURL: URL, metadata: TrackMetadata, options: WriteOptions) -> FileWriteResult {
        do {
            let inputData = try Data(contentsOf: fileURL)
            let parsed = parseID3v2(data: inputData)
            var textFrames = parsed.textFrames
            var txxxFrames = parsed.txxx
            var comment = parsed.comment
            var changes: [String] = []

            var touchedFrameIDs = Set<String>()
            var touchedTXXXDescriptors = Set<String>()
            var touchComment = false

            for mapping in options.mappings {
                let rendered = templateEngine.render(template: mapping.template, metadata: metadata, notationOverride: mapping.notation, options: options)
                switch mapping.target {
                case .comment:
                    touchComment = true
                    let updated = apply(mode: mapping.mode, current: comment, rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != comment { changes.append("COMM: '\(comment ?? "")' -> '\(updated ?? "")'") }
                    comment = updated
                case .tkey:
                    touchedFrameIDs.insert("TKEY")
                    let updated = apply(mode: mapping.mode, current: textFrames["TKEY"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TKEY"] { changes.append("TKEY: '\(textFrames["TKEY"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TKEY"] = updated
                case .grouping:
                    touchedFrameIDs.insert("TIT1")
                    let updated = apply(mode: mapping.mode, current: textFrames["TIT1"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TIT1"] { changes.append("TIT1: '\(textFrames["TIT1"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TIT1"] = updated
                case .title:
                    touchedFrameIDs.insert("TIT2")
                    let updated = apply(mode: mapping.mode, current: textFrames["TIT2"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TIT2"] { changes.append("TIT2: '\(textFrames["TIT2"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TIT2"] = updated
                case .bpm:
                    touchedFrameIDs.insert("TBPM")
                    let updated = apply(mode: mapping.mode, current: textFrames["TBPM"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TBPM"] { changes.append("TBPM: '\(textFrames["TBPM"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TBPM"] = updated
                case .artist:
                    touchedFrameIDs.insert("TPE1")
                    let updated = apply(mode: mapping.mode, current: textFrames["TPE1"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TPE1"] { changes.append("TPE1: '\(textFrames["TPE1"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TPE1"] = updated
                case .genre:
                    touchedFrameIDs.insert("TCON")
                    let updated = apply(mode: mapping.mode, current: textFrames["TCON"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TCON"] { changes.append("TCON: '\(textFrames["TCON"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TCON"] = updated
                case .year:
                    touchedFrameIDs.insert("TYER")
                    let updated = apply(mode: mapping.mode, current: textFrames["TYER"], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != textFrames["TYER"] { changes.append("TYER: '\(textFrames["TYER"] ?? "")' -> '\(updated ?? "")'") }
                    textFrames["TYER"] = updated
                case .txxx(let descriptor):
                    touchedTXXXDescriptors.insert(descriptor)
                    let updated = apply(mode: mapping.mode, current: txxxFrames[descriptor], rendered: rendered, forceOverwrite: options.forceOverwrite)
                    if updated != txxxFrames[descriptor] { changes.append("TXXX:\(descriptor): '\(txxxFrames[descriptor] ?? "")' -> '\(updated ?? "")'") }
                    txxxFrames[descriptor] = updated
                }
            }

            if options.dryRun {
                return FileWriteResult(fileURL: fileURL, success: true, dryRun: true, changes: changes, errors: [])
            }

            var frames: [Data] = []
            for frame in parsed.frames {
                if frame.id == "COMM", touchComment { continue }
                if touchedFrameIDs.contains(frame.id) { continue }

                if frame.id == "TXXX" {
                    let (descriptor, _) = decodeTXXXFrame(frame.payload[...])
                    if touchedTXXXDescriptors.contains(descriptor) {
                        continue
                    }
                }
                frames.append(frame.rawFrame)
            }

            for id in touchedFrameIDs.sorted() {
                if let value = textFrames[id], !value.isEmpty {
                    frames.append(makeTextFrame(id: id, value: value))
                }
            }

            if touchComment, let comment, !comment.isEmpty {
                frames.append(makeCommentFrame(value: comment))
            }

            for descriptor in touchedTXXXDescriptors.sorted() {
                if let value = txxxFrames[descriptor], !value.isEmpty {
                    frames.append(makeTXXXFrame(descriptor: descriptor, value: value))
                }
            }

            let newTag = makeTag(frames: frames, version: options.id3Version)
            let audioData = inputData.subdata(in: parsed.audioStart..<inputData.count)
            let finalData = newTag + audioData

            let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".tmp")
            try finalData.write(to: tempURL, options: .atomic)
            let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            try FileManager.default.setAttributes(attrs, ofItemAtPath: tempURL.path)
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL, backupItemName: nil)

            return FileWriteResult(fileURL: fileURL, success: true, dryRun: false, changes: changes, errors: [])
        } catch {
            return FileWriteResult(fileURL: fileURL, success: false, dryRun: options.dryRun, changes: [], errors: [error.localizedDescription])
        }
    }

    private func apply(mode: WriteMode, current: String?, rendered: String, forceOverwrite: Bool) -> String? {
        let currentValue = current ?? ""
        switch mode {
        case .overwrite:
            if !forceOverwrite && !currentValue.isEmpty { return current }
            return rendered
        case .prepend:
            return rendered + (currentValue.isEmpty ? "" : " " + currentValue)
        case .append:
            return (currentValue.isEmpty ? "" : currentValue + " ") + rendered
        case .onlyIfEmpty:
            return currentValue.isEmpty ? rendered : current
        }
    }
}

private struct ParsedID3 {
    var majorVersion: UInt8
    var audioStart: Int
    var frames: [ParsedFrame]
    var textFrames: [String: String]
    var txxx: [String: String]
    var comment: String?
}

private struct ParsedFrame {
    var id: String
    var flags: (UInt8, UInt8)
    var payload: Data
    var rawFrame: Data
}

private func parseID3v2(data: Data) -> ParsedID3 {
    guard data.count >= 10, String(data: data[0..<3], encoding: .isoLatin1) == "ID3" else {
        return ParsedID3(majorVersion: 3, audioStart: 0, frames: [], textFrames: [:], txxx: [:], comment: nil)
    }

    let majorVersion = data[3]
    let tagSize = syncSafeToInt(bytes: [data[6], data[7], data[8], data[9]])
    let tagEnd = min(10 + tagSize, data.count)
    var index = 10
    var parsedFrames: [ParsedFrame] = []
    var textFrames: [String: String] = [:]
    var txxx: [String: String] = [:]
    var comment: String?

    while index + 10 <= tagEnd {
        let frameID = String(data: data[index..<(index+4)], encoding: .isoLatin1) ?? ""
        if frameID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }

        let frameSize: Int
        if majorVersion == 4 {
            frameSize = syncSafeToInt(bytes: [data[index+4], data[index+5], data[index+6], data[index+7]])
        } else {
            frameSize = Int(bigEndianUInt32(data[(index+4)..<(index+8)]))
        }

        let frameDataStart = index + 10
        let frameDataEnd = frameDataStart + frameSize
        guard frameSize > 0, frameDataEnd <= tagEnd else { break }

        let frameData = data[frameDataStart..<frameDataEnd]
        let rawFrame = data[index..<frameDataEnd]
        let parsedFrame = ParsedFrame(
            id: frameID,
            flags: (data[index+8], data[index+9]),
            payload: Data(frameData),
            rawFrame: Data(rawFrame)
        )
        parsedFrames.append(parsedFrame)

        if frameID.hasPrefix("T") && frameID != "TXXX" {
            textFrames[frameID] = decodeTextFrame(frameData)
        } else if frameID == "TXXX" {
            let (descriptor, value) = decodeTXXXFrame(frameData)
            if !descriptor.isEmpty { txxx[descriptor] = value }
        } else if frameID == "COMM" {
            comment = decodeCOMMFrame(frameData)
        }

        index = frameDataEnd
    }

    return ParsedID3(majorVersion: majorVersion, audioStart: tagEnd, frames: parsedFrames, textFrames: textFrames, txxx: txxx, comment: comment)
}

private func decodeTextFrame(_ data: Data.SubSequence) -> String {
    guard let encoding = data.first else { return "" }
    let payload = data.dropFirst()
    switch encoding {
    case 0: return String(data: payload, encoding: .isoLatin1)?.trimmingCharacters(in: .controlCharacters) ?? ""
    default: return String(data: payload, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? ""
    }
}

private func decodeTXXXFrame(_ data: Data.SubSequence) -> (String, String) {
    guard let encoding = data.first else { return ("", "") }
    let payload = Data(data.dropFirst())
    let separator = Data([0])
    guard let range = payload.range(of: separator) else { return ("", "") }
    let descriptorData = payload.subdata(in: 0..<range.lowerBound)
    let valueData = payload.subdata(in: range.upperBound..<payload.count)
    let desc = encoding == 0 ? (String(data: descriptorData, encoding: .isoLatin1) ?? "") : (String(data: descriptorData, encoding: .utf8) ?? "")
    let value = encoding == 0 ? (String(data: valueData, encoding: .isoLatin1) ?? "") : (String(data: valueData, encoding: .utf8) ?? "")
    return (desc, value)
}

private func decodeCOMMFrame(_ data: Data.SubSequence) -> String {
    guard data.count > 5 else { return "" }
    let encoding = data.first ?? 3
    let payload = Data(data.dropFirst(4))
    let separator = Data([0])
    guard let range = payload.range(of: separator) else {
        return encoding == 0 ? (String(data: payload, encoding: .isoLatin1) ?? "") : (String(data: payload, encoding: .utf8) ?? "")
    }
    let commentData = payload.subdata(in: range.upperBound..<payload.count)
    return encoding == 0 ? (String(data: commentData, encoding: .isoLatin1) ?? "") : (String(data: commentData, encoding: .utf8) ?? "")
}

private func makeTag(frames: [Data], version: ID3Version) -> Data {
    let body = frames.reduce(Data(), +)
    var header = Data("ID3".utf8)
    switch version {
    case .v23: header.append(contentsOf: [3, 0])
    case .v24: header.append(contentsOf: [4, 0])
    }
    header.append(0)
    header.append(contentsOf: intToSyncSafe(body.count))
    return header + body
}

private func makeTextFrame(id: String, value: String) -> Data {
    var payload = Data([3])
    payload.append(value.data(using: .utf8) ?? Data())
    return makeFrame(id: id, payload: payload)
}

private func makeTXXXFrame(descriptor: String, value: String) -> Data {
    var payload = Data([3])
    payload.append(descriptor.data(using: .utf8) ?? Data())
    payload.append(0)
    payload.append(value.data(using: .utf8) ?? Data())
    return makeFrame(id: "TXXX", payload: payload)
}

private func makeCommentFrame(value: String) -> Data {
    var payload = Data([3])
    payload.append("eng".data(using: .ascii) ?? Data())
    payload.append(0)
    payload.append(value.data(using: .utf8) ?? Data())
    return makeFrame(id: "COMM", payload: payload)
}

private func makeFrame(id: String, payload: Data) -> Data {
    var data = Data(id.utf8)
    data.append(contentsOf: bigEndianBytes(UInt32(payload.count)))
    data.append(contentsOf: [0, 0])
    data.append(payload)
    return data
}

private func bigEndianUInt32(_ data: Data.SubSequence) -> UInt32 {
    data.reduce(0) { ($0 << 8) | UInt32($1) }
}

private func bigEndianBytes(_ value: UInt32) -> [UInt8] {
    [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
}

private func syncSafeToInt(bytes: [UInt8]) -> Int {
    (Int(bytes[0]) << 21) | (Int(bytes[1]) << 14) | (Int(bytes[2]) << 7) | Int(bytes[3])
}

private func intToSyncSafe(_ value: Int) -> [UInt8] {
    [UInt8((value >> 21) & 0x7F), UInt8((value >> 14) & 0x7F), UInt8((value >> 7) & 0x7F), UInt8(value & 0x7F)]
}
