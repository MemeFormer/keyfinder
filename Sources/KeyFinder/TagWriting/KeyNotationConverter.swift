import Foundation

enum KeyNotationConverter {
    private static let camelotToTraditional: [String: String] = [
        "1A": "G#m", "2A": "D#m", "3A": "A#m", "4A": "Fm", "5A": "Cm", "6A": "Gm", "7A": "Dm", "8A": "Am", "9A": "Em", "10A": "Bm", "11A": "F#m", "12A": "C#m",
        "1B": "B", "2B": "F#", "3B": "C#", "4B": "G#", "5B": "D#", "6B": "A#", "7B": "F", "8B": "C", "9B": "G", "10B": "D", "11B": "A", "12B": "E"
    ]

    static func openFromCamelot(_ camelot: String?) -> String? {
        guard let camelot else { return nil }
        guard camelot.count >= 2, let mode = camelot.last else { return nil }
        let number = Int(camelot.dropLast())
        guard let number else { return nil }
        return "\(number)\(mode == "A" ? "m" : "d")"
    }

    static func traditionalFromCamelot(_ camelot: String?) -> String? {
        guard let camelot else { return nil }
        return camelotToTraditional[camelot.uppercased()]
    }
}
