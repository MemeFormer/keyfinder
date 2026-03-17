import Foundation
import CryptoKit

// MARK: - File Hash Utilities
/// Provides file fingerprinting for caching analysis results
struct FileHasher {
    /// Cache entry storing analysis metadata
    struct CacheEntry: Codable {
        let fileHash: String
        let modificationDate: Date
        let analysisDate: Date
        let key: String
        let camelotNotation: String
        let bpm: String
        let confidence: Double
        let duration: TimeInterval
        let energy: String
        let fileSize: Int64
    }

    private static let cacheDirectory: URL = {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("KeyFinder", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    /// Quick hash using first/last bytes + file size (fast check for changes)
    static func quickHash(for url: URL) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64,
              let modDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        // Combine file size and modification date for quick check
        let quickString = "\(fileSize)-\(modDate.timeIntervalSince1970)"
        let data = Data(quickString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Full hash of file content (for accurate cache validation)
    static func fullHash(for url: URL) async -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }

        var hasher = SHA256()
        let bufferSize = 1024 * 1024 // 1MB chunks

        // Read file in chunks
        while let data = try? handle.read(upToCount: bufferSize), !data.isEmpty {
            hasher.update(data: data)
        }

        let hash = hasher.finalize()
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Get cached analysis result if file hasn't changed
    static func getCachedAnalysis(for url: URL) -> CacheEntry? {
        let cacheKey = cacheKey(for: url)
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")

        guard let data = try? Data(contentsOf: cacheFile),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else {
            return nil
        }

        // Verify file hasn't changed
        guard let currentHash = quickHash(for: url),
              currentHash == entry.fileHash else {
            return nil
        }

        return entry
    }

    /// Save analysis result to cache
    static func saveAnalysis(_ entry: CacheEntry, for url: URL) {
        let cacheKey = cacheKey(for: url)
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")

        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: cacheFile)
    }

    /// Generate cache key from URL
    private static func cacheKey(for url: URL) -> String {
        let pathString = url.path
        let data = Data(pathString.utf8)
        let hash = SHA256.hash(data: data)
        return String(hash.prefix(16).compactMap { String(format: "%02x", $0) }.joined())
    }

    /// Clear all cached analysis results
    static func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get cache size in bytes
    static func cacheSize() -> Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}

// MARK: - Performance Utilities
/// Utilities for performance monitoring and optimization
struct PerformanceUtils {
    /// Get optimal batch size based on system capabilities
    static var optimalBatchSize: Int {
        let processorCount = ProcessInfo.processInfo.activeProcessorCount
        let isAppleSilicon = isRunningOnAppleSilicon()

        // Apple M-series can handle more concurrent tasks efficiently
        // Intel Macs benefit from smaller batches due to different architecture
        if isAppleSilicon {
            return max(processorCount, 8) // At least 8 for Apple Silicon
        } else {
            return min(processorCount, 4) // Conservative for Intel
        }
    }

    /// Check if running on Apple Silicon
    static func isRunningOnAppleSilicon() -> Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    /// Get recommended FFT size for the system
    static func recommendedFFTSize() -> Int {
        // Apple Silicon has better performance with larger FFT sizes
        if isRunningOnAppleSilicon() {
            return 32768 // Better resolution on ARM
        } else {
            return 16384 // Conservative for Intel
        }
    }

    /// Memory usage estimate for audio processing
    static func estimateMemoryUsage(sampleCount: Int, fftSize: Int) -> Int64 {
        // Rough memory estimate in bytes:
        // - samples array: 4 bytes * sampleCount
        // - FFT buffers: 4 bytes * fftSize * 4 (real, imag, window, output)
        // - chromagram: 8 bytes * 12 * frames
        let frames = max(1, (sampleCount - fftSize) / (fftSize / 8))
        return Int64(sampleCount * 4 + fftSize * 16 + 96 * frames)
    }
}

// MARK: - Async Utilities
/// Extension for better async handling
extension Task where Success == Never, Failure == Never {
    /// Sleep for specified milliseconds
    static func sleep(milliseconds: UInt64) async throws {
        let nanoseconds = UInt64(milliseconds) * 1_000_000
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

// MARK: - Memory Management
/// Memory-efficient audio buffer processing
final class AudioBufferPool {
    private var availableBuffers: [[Float]] = []
    private let bufferSize: Int
    private let lock = NSLock()

    init(bufferSize: Int, initialCount: Int = 4) {
        self.bufferSize = bufferSize
        for _ in 0..<initialCount {
            availableBuffers.append([Float](repeating: 0, count: bufferSize))
        }
    }

    func acquireBuffer() -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        if let buffer = availableBuffers.popLast() {
            return buffer
        }
        return [Float](repeating: 0, count: bufferSize)
    }

    func releaseBuffer(_ buffer: inout [Float]) {
        lock.lock()
        defer { lock.unlock() }

        // Reset buffer to zeros - create new empty buffer
        buffer = [Float](repeating: 0, count: bufferSize)
        availableBuffers.append(buffer)
    }
}
