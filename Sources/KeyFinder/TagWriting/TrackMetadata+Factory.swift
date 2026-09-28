import Foundation

extension TrackMetadata {
    init(filename: String?, filepath: String?) {
        self.init(
            keyCamelot: nil,
            keyOpen: nil,
            keyTraditional: nil,
            bpm: nil,
            energy: nil,
            title: nil,
            artist: nil,
            album: nil,
            year: nil,
            filename: filename,
            filepath: filepath,
            trackNumber: nil,
            comment: nil,
            grouping: nil,
            tkey: nil,
            customText: [:]
        )
    }
}
