import SwiftUI
import AVFoundation

/// BeatGridOverlayView - Visualizes the beatgrid on top of the waveform
struct BeatGridOverlayView: View {
    let beatGrid: BeatGridData?
    let duration: TimeInterval
    @Binding var currentPosition: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            if let grid = beatGrid, grid.hasValidGrid {
                ZStack(alignment: .leading) {
                    // Draw beat markers
                    ForEach(Array(grid.beats.enumerated()), id: \.offset) { index, beat in
                        let xPosition = CGFloat(beat.time / duration) * geometry.size.width

                        // Beat marker
                        Rectangle()
                            .fill(beat.isDownbeat ? Color.red.opacity(0.8) : Color.blue.opacity(0.4))
                            .frame(width: beat.isDownbeat ? 2 : 1)
                            .position(x: xPosition, y: geometry.size.height / 2)

                        // Beat number label for downbeats
                        if beat.isDownbeat {
                            Text("1")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.red)
                                .position(x: xPosition, y: geometry.size.height - 8)
                        } else if beat.beatNumber <= 4 {
                            Text("\(beat.beatNumber)")
                                .font(.system(size: 6))
                                .foregroundColor(.blue.opacity(0.7))
                                .position(x: xPosition, y: geometry.size.height - 8)
                        }
                    }

                    // Current position indicator
                    let positionX = CGFloat(currentPosition / duration) * geometry.size.width
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 2)
                        .position(x: positionX, y: geometry.size.height / 2)
                }
            }
        }
    }
}

/// MiniBeatGridView - Compact beatgrid visualization for list views
struct MiniBeatGridView: View {
    let beatGrid: BeatGridData?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            if let grid = beatGrid, grid.hasValidGrid {
                Canvas { context, size in
                    let duration = grid.beats.last?.time ?? 1.0

                    for beat in grid.beats {
                        let x = CGFloat(beat.time / duration) * size.width

                        // Draw beat line
                        let lineColor = beat.isDownbeat ? Color.red : Color.blue.opacity(0.5)
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))

                        context.stroke(path, with: .color(lineColor), lineWidth: beat.isDownbeat ? 1.5 : 0.5)
                    }
                }
            } else {
                // Placeholder when no beatgrid
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .frame(width: width, height: height)
    }
}

/// WaveformWithBeatGridView - Combined waveform and beatgrid visualization
struct WaveformWithBeatGridView: View {
    let filePath: URL
    let beatGrid: BeatGridData?
    @Binding var currentPosition: TimeInterval
    @State private var waveformData: [Float] = []
    @State private var duration: TimeInterval = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Waveform
                HStack(spacing: 0.5) {
                    ForEach(Array(waveformData.enumerated()), id: \.offset) { index, amplitude in
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: max(0.5, geometry.size.width / CGFloat(waveformData.count) - 0.5))
                            .frame(height: max(1, CGFloat(amplitude) * geometry.size.height * 0.8))
                    }
                }
                .frame(height: geometry.size.height, alignment: .center)

                // Beatgrid overlay
                if let grid = beatGrid {
                    BeatGridOverlayView(beatGrid: grid, duration: duration, currentPosition: $currentPosition)
                }
            }
        }
        .onAppear {
            loadAudioData()
        }
    }

    private func loadAudioData() {
        DispatchQueue.global(qos: .utility).async {
            do {
                let audioFile = try AVAudioFile(forReading: filePath)
                let format = audioFile.processingFormat
                let sampleRate = format.sampleRate
                let frameCount = AVAudioFrameCount(audioFile.length)

                duration = Double(frameCount) / sampleRate

                // Sample 200 points across the track
                let targetSamples = 200
                let step = max(1, Int(frameCount) / targetSamples)

                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(min(4096, step))) else {
                    return
                }

                var waveform: [Float] = []

                for i in stride(from: 0, to: Int(frameCount), by: step) {
                    audioFile.framePosition = AVAudioFramePosition(i)
                    let framesToRead = AVAudioFrameCount(min(4096, Int(frameCount) - i))

                    do {
                        try audioFile.read(into: buffer, frameCount: framesToRead)
                    } catch {
                        continue
                    }

                    guard let floatData = buffer.floatChannelData else { continue }
                    let actualFrames = Int(buffer.frameLength)

                    var sum: Float = 0
                    for j in 0..<actualFrames {
                        let sample = floatData[0][j]
                        sum += sample * sample
                    }
                    let rms = sqrt(sum / Float(actualFrames))
                    waveform.append(rms)
                }

                if let maxValue = waveform.max(), maxValue > 0 {
                    waveform = waveform.map { $0 / maxValue }
                }

                DispatchQueue.main.async {
                    self.waveformData = waveform
                }
            } catch {
                // Silently fail
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BeatGridOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        // Pre-compute sample beats outside the view builder
        let sampleBeats: [BeatGridData.BeatData] = {
            var beats: [BeatGridData.BeatData] = []
            for i in 0..<32 {
                let beat = BeatGridData.BeatData(
                    time: Double(i) * 0.5,
                    strength: i % 4 == 0 ? 1.0 : 0.6,
                    isDownbeat: i % 4 == 0,
                    beatNumber: (i % 4) + 1
                )
                beats.append(beat)
            }
            return beats
        }()

        let sampleGrid = BeatGridData(
            bpm: 120.0,
            timeSignature: "4/4",
            firstDownbeatTime: 0.0,
            beats: sampleBeats,
            hasValidGrid: true
        )

        return VStack(spacing: 20) {
            Text("BeatGrid Overlay (300x60)")
                .font(.headline)

            BeatGridOverlayView(
                beatGrid: sampleGrid,
                duration: 16.0,
                currentPosition: .constant(2.5)
            )
            .frame(height: 60)
            .background(Color.black.opacity(0.1))

            Text("Mini BeatGrid (200x20)")
                .font(.headline)

            MiniBeatGridView(beatGrid: sampleGrid, width: 200, height: 20)
                .background(Color.white)
        }
        .padding()
    }
}
#endif
