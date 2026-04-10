import XCTest
@testable import KeyFinder

final class TemplateEngineTests: XCTestCase {
    func testTemplateExpansionSupportsCoreTokensAndEscape() {
        let engine = TemplateEngine()
        let metadata = TrackMetadata(
            keyCamelot: "8A",
            keyOpen: "8m",
            keyTraditional: "Am",
            bpm: 124,
            energy: "7",
            title: "Track",
            artist: "Artist",
            album: "Album",
            year: "2024",
            filename: "song.mp3",
            filepath: "/tmp/song.mp3",
            trackNumber: "1",
            comment: nil,
            grouping: nil,
            tkey: nil,
            customText: ["INITIALKEY": "8A"]
        )

        let output = engine.render(template: #"\[literal\] [KeyCamelot] [BPM] [Custom:INITIALKEY]"#, metadata: metadata, options: WriteOptions())
        XCTAssertEqual(output, "[literal] 8A 124 8A")
    }
}
