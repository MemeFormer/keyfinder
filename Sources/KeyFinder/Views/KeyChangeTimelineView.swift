import SwiftUI

struct KeyChangeTimelineView: View {
    let keyChanges: [KeyChange]
    let duration: TimeInterval // Total track duration
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path")
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.tertiaryTextColor)
                Text("KEY CHANGES")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.tertiaryTextColor)
                Spacer()
                Text("\(keyChanges.count) detected")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(themeManager.tertiaryTextColor)
            }

            if keyChanges.isEmpty {
                Text("No key changes detected")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(themeManager.tertiaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                // Timeline visualization
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(themeManager.surfaceColor)
                            .frame(height: 4)
                            .cornerRadius(2)

                        // Key change markers
                        ForEach(Array(keyChanges.enumerated()), id: \.element.id) { index, change in
                            let position = calculatePosition(for: change, in: geometry.size.width)

                            VStack(spacing: 2) {
                                // Vertical line marker
                                Rectangle()
                                    .fill(keyColor(for: change.confidence))
                                    .frame(width: 2, height: 20)

                                // Key label
                                VStack(spacing: 0) {
                                    Text(change.key)
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(keyColor(for: change.confidence))
                                    Text(change.camelotNotation)
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundColor(themeManager.tertiaryTextColor)
                                    Text(formatTimestamp(change.timestamp))
                                        .font(.system(size: 6, design: .monospaced))
                                        .foregroundColor(themeManager.tertiaryTextColor)
                                }
                                .padding(4)
                                .background(themeManager.surfaceColor)
                                .cornerRadius(2)
                            }
                            .offset(x: position - 1, y: -25)
                        }
                    }
                }
                .frame(height: 80)
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(themeManager.surfaceColor.opacity(0.5))
        .cornerRadius(4)
    }

    private func calculatePosition(for change: KeyChange, in width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(change.timestamp / duration) * width
    }

    private func keyColor(for confidence: Double) -> Color {
        if confidence > 0.75 { return .green }
        if confidence > 0.50 { return .yellow }
        return .orange
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
