import SwiftUI

/// Panel for displaying and managing potential duplicate tracks
struct DuplicatesPanel: View {
    @ObservedObject var model: AudioAnalysisModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var bpmTolerance: Double = 0.5
    @State private var durationTolerance: Double = 2.0
    @State private var filenameSimilarity: Double = 0.7

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DUPLICATE DETECTION")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Button(action: {
                    // Close the sheet
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(themeManager.surfaceColor)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Detection Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DETECTION SETTINGS")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(themeManager.tertiaryTextColor)

                            HStack {
                                Text("BPM Tolerance:")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .frame(width: 120, alignment: .leading)

                                Slider(value: $bpmTolerance, in: 0.1...2.0, step: 0.1)
                                    .frame(maxWidth: 200)

                                Text("±\(String(format: "%.1f", bpmTolerance))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(themeManager.textColor)
                                    .frame(width: 40)
                            }

                            HStack {
                                Text("Duration Tolerance:")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .frame(width: 120, alignment: .leading)

                                Slider(value: $durationTolerance, in: 1...10, step: 0.5)
                                    .frame(maxWidth: 200)

                                Text("±\(String(format: "%.1f", durationTolerance))s")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(themeManager.textColor)
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("Filename Similarity:")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .frame(width: 120, alignment: .leading)

                                Slider(value: $filenameSimilarity, in: 0.5...1.0, step: 0.05)
                                    .frame(maxWidth: 200)

                                Text("\(Int(filenameSimilarity * 100))%")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(themeManager.textColor)
                                    .frame(width: 40)
                            }

                            Button(action: {
                                model.detectDuplicates(
                                    bpmTolerance: bpmTolerance,
                                    durationTolerance: durationTolerance,
                                    filenameSimilarity: filenameSimilarity
                                )
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("SCAN FOR DUPLICATES")
                                }
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(themeManager.accentColor)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                    }

                    // Results
                    if !model.duplicateGroups.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("DETECTED DUPLICATES")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(themeManager.tertiaryTextColor)

                                    Spacer()

                                    // Export button
                                    Button(action: {
                                        if let url = model.exportDuplicatesReport() {
                                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Export Report")
                                        }
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(model.duplicateGroups.count) groups")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.orange)
                                }

                                ForEach(Array(model.duplicateGroups.enumerated()), id: \.element.id) { groupIndex, group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("Group \(groupIndex + 1): \(group.duplicateCount) duplicate(s)")
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundColor(themeManager.textColor)
                                        }

                                        // Match reasons
                                        Text("Match: \(group.matchReasons.joined(separator: ", "))")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(themeManager.tertiaryTextColor)

                                        // Tracks in this group
                                        ForEach(Array(group.tracks.enumerated()), id: \.element.id) { trackIndex, track in
                                            HStack(spacing: 12) {
                                                // Track icon
                                                Image(systemName: trackIndex == 0 ? "music.note" : "music.note.list")
                                                    .foregroundColor(trackIndex == 0 ? themeManager.accentColor : themeManager.tertiaryTextColor)
                                                    .font(.system(size: 12))

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(track.fileName)
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .foregroundColor(themeManager.textColor)
                                                        .lineLimit(1)

                                                    HStack(spacing: 8) {
                                                        if let key = track.key {
                                                            Text(key)
                                                                .font(.system(size: 8, design: .monospaced))
                                                                .foregroundColor(themeManager.secondaryTextColor)
                                                        }
                                                        if let bpm = track.bpm {
                                                            Text("\(bpm) BPM")
                                                                .font(.system(size: 8, design: .monospaced))
                                                                .foregroundColor(themeManager.tertiaryTextColor)
                                                        }
                                                        Text(String(format: "%.1fs", track.duration))
                                                            .font(.system(size: 8, design: .monospaced))
                                                            .foregroundColor(themeManager.tertiaryTextColor)
                                                    }
                                                }

                                                Spacer()

                                                // Show in folder button
                                                Button(action: {
                                                    NSWorkspace.shared.selectFile(track.filePath.path, inFileViewerRootedAtPath: track.filePath.deletingLastPathComponent().path)
                                                }) {
                                                    Image(systemName: "folder")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(themeManager.tertiaryTextColor)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(trackIndex == 0 ? themeManager.surfaceColor.opacity(0.5) : Color.clear)
                                            .cornerRadius(4)
                                        }
                                    }
                                    .padding(12)
                                    .background(themeManager.surfaceColor.opacity(0.3))
                                    .cornerRadius(8)

                                    if groupIndex < model.duplicateGroups.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(12)
                        }
                    } else if model.tracks.isEmpty {
                        Text("No tracks loaded. Add tracks to analyze them for duplicates.")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(themeManager.tertiaryTextColor)
                            .padding()
                            .background(themeManager.surfaceColor)
                            .cornerRadius(4)
                    } else {
                        Text("Click 'Scan for Duplicates' to detect potential duplicate tracks in your collection.")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(themeManager.tertiaryTextColor)
                            .padding()
                            .background(themeManager.surfaceColor)
                            .cornerRadius(4)
                    }
                }
                .padding(20)
            }
        }
        .background(themeManager.backgroundColor)
    }
}
