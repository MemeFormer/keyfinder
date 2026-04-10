import XCTest
@testable import KeyFinder

final class ID3TagWriterTests: XCTestCase {
    func testWriteAndReadRoundTrip() throws {
        let writer = ID3TagWriter()
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
        try Data([0xFF, 0xFB, 0x90, 0x64, 0, 0, 0, 0]).write(to: temp)

        let metadata = TrackMetadata(
            keyCamelot: "8A",
            keyOpen: "8m",
            keyTraditional: "Am",
            bpm: 124,
            energy: "6",
            title: "Test Title",
            artist: "Tester",
            album: nil,
            year: "2025",
            filename: temp.lastPathComponent,
            filepath: temp.path,
            trackNumber: nil,
            comment: nil,
            grouping: nil,
            tkey: nil,
            customText: ["MIXEDINKEY": "8A"]
        )

        let result = writer.writeTags(fileURL: temp, metadata: metadata, options: WriteOptions(forceOverwrite: true))
        XCTAssertTrue(result.success)

        let read = try writer.readTags(fileURL: temp)
        XCTAssertEqual(read.tkey, "Am")
        XCTAssertEqual(read.comment, "8A 124 BPM")
        XCTAssertEqual(read.customText["MIXEDINKEY"], "8A")
    }

    func testDryRunDoesNotModifyFile() throws {
        let writer = ID3TagWriter()
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
        let original = Data([1,2,3,4,5])
        try original.write(to: temp)

        let result = writer.writeTags(fileURL: temp, metadata: TrackMetadata(filename: temp.lastPathComponent, filepath: temp.path), options: WriteOptions(dryRun: true))
        XCTAssertTrue(result.success)
        XCTAssertEqual(try Data(contentsOf: temp), original)
    }

    func testWritePreservesExistingArtistAndTitleFrames() throws {
        let writer = ID3TagWriter()
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")

        let initialTag = makeTestTag(frames: [
            makeTextFrame(id: "TIT2", value: "Original Title"),
            makeTextFrame(id: "TPE1", value: "Original Artist")
        ])
        let audioPayload = Data([0xFF, 0xFB, 0x90, 0x64, 0, 0, 0, 0])
        try (initialTag + audioPayload).write(to: temp)

        let metadata = TrackMetadata(
            keyCamelot: "8A",
            keyOpen: "8m",
            keyTraditional: "Am",
            bpm: 124,
            energy: nil,
            title: nil,
            artist: nil,
            album: nil,
            year: nil,
            filename: temp.lastPathComponent,
            filepath: temp.path,
            trackNumber: nil,
            comment: nil,
            grouping: nil,
            tkey: nil,
            customText: [:]
        )

        let result = writer.writeTags(fileURL: temp, metadata: metadata, options: WriteOptions(forceOverwrite: true))
        XCTAssertTrue(result.success)

        let read = try writer.readTags(fileURL: temp)
        XCTAssertEqual(read.title, "Original Title")
        XCTAssertEqual(read.artist, "Original Artist")
        XCTAssertEqual(read.comment, "8A 124 BPM")
    }
}

private func makeTestTag(frames: [Data]) -> Data {
    let body = frames.reduce(Data(), +)
    var header = Data("ID3".utf8)
    header.append(contentsOf: [3, 0, 0])
    header.append(contentsOf: [UInt8((body.count >> 21) & 0x7F), UInt8((body.count >> 14) & 0x7F), UInt8((body.count >> 7) & 0x7F), UInt8(body.count & 0x7F)])
    return header + body
}

private func makeTextFrame(id: String, value: String) -> Data {
    var payload = Data([3])
    payload.append(value.data(using: .utf8) ?? Data())

    var frame = Data(id.utf8)
    let size = UInt32(payload.count)
    frame.append(contentsOf: [UInt8((size >> 24) & 0xFF), UInt8((size >> 16) & 0xFF), UInt8((size >> 8) & 0xFF), UInt8(size & 0xFF)])
    frame.append(contentsOf: [0, 0])
    frame.append(payload)
    return frame
}
