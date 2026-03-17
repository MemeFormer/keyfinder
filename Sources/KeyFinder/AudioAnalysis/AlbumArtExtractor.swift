import Foundation
import AVFoundation
import AppKit

class AlbumArtExtractor {
    func extractAlbumArt(from url: URL) -> NSImage? {
        let asset = AVAsset(url: url)

        // Use synchronous metadata access for simplicity
        let metadata = asset.commonMetadata
        for item in metadata {
            guard let key = item.commonKey?.rawValue,
                  key == "artwork",
                  let value = item.value as? Data else {
                continue
            }

            return NSImage(data: value)
        }

        return nil
    }
}
