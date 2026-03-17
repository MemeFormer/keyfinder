import SwiftUI
import UniformTypeIdentifiers

struct BatchContentView: View {
    @StateObject private var model = AudioAnalysisModel()
    @State private var isDragOver = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("KEY FINDER")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    if !model.tracks.isEmpty {
                        Button(action: { model.clearAll() }) {
                            Text("CLEAR ALL")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 20)

                if model.tracks.isEmpty {
                    dropZoneView
                } else {
                    trackListView
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }

    private var dropZoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(.white.opacity(0.3))

            Text("DROP AUDIO FILES")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            Text("SUPPORTS MULTIPLE FILES")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(
                    isDragOver ? Color.white : Color.white.opacity(0.2),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                )
                .padding(40)
        )
    }

    private var trackListView: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 12) {
                Text("ART")
                    .frame(width: 50)
                Text("TRACK")
                    .frame(width: 200, alignment: .leading)
                Text("KEY")
                    .frame(width: 60)
                Text("CAMELOT")
                    .frame(width: 80)
                Text("BPM")
                    .frame(width: 60)
                Spacer()
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(Array(model.tracks.enumerated()), id: \.element.id) { index, track in
                        TrackRowView(track: track) {
                            model.removeTrack(at: index)
                        }
                    }
                }
            }

            if model.isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("ANALYZING...")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(10)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let supportedExtensions = ["mp3", "wav", "m4a", "flac", "aiff", "aif"]
        var urls: [URL] = []

        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }

                let fileExtension = url.pathExtension.lowercased()
                if supportedExtensions.contains(fileExtension) {
                    urls.append(url)
                }

                if provider == providers.last {
                    Task { @MainActor in
                        await model.addFiles(urls)
                    }
                }
            }
        }

        return true
    }
}

struct TrackRowView: View {
    let track: TrackAnalysis
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Album art
            if let albumArt = track.albumArt {
                Image(nsImage: albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: 50, height: 50)
            }

            // Track name
            Text(track.shortFileName)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 200, alignment: .leading)
                .lineLimit(1)

            // Key
            if track.isAnalyzing {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 60)
            } else {
                Text(track.key ?? "--")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 60)
            }

            // Camelot
            Text(track.camelotNotation ?? "--")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 80)

            // BPM
            Text(track.bpm ?? "--")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60)

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .contentShape(Rectangle())
    }
}
