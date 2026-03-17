import SwiftUI

struct CamelotWheelView: View {
    let tracks: [TrackAnalysis]
    @Binding var selectedTrack: TrackAnalysis?
    @EnvironmentObject var themeManager: ThemeManager

    // Camelot wheel positions (12 positions, inner = minor, outer = major)
    private let camelotPositions: [String] = [
        "12B", "1B", "2B", "3B", "4B", "5B", "6B", "7B", "8B", "9B", "10B", "11B",
        "12A", "1A", "2A", "3A", "4A", "5A", "6A", "7A", "8A", "9A", "10A", "11A"
    ]

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 40

            ZStack {
                // Background circle
                Circle()
                    .stroke(themeManager.borderColor, lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)

                // Inner circle (minor keys)
                Circle()
                    .stroke(themeManager.borderColor, lineWidth: 1)
                    .frame(width: radius * 1.3, height: radius * 1.3)

                // Draw all positions
                ForEach(0..<24, id: \.self) { index in
                    let camelot = camelotPositions[index]
                    let isMajor = index < 12
                    let position = index % 12
                    let angle = Double(position) * 30 - 90 // Start at 12 o'clock
                    let distance = isMajor ? radius * 0.85 : radius * 0.55

                    let tracksAtPosition = tracks.filter { $0.camelotNotation == camelot }
                    let isSelected = selectedTrack?.camelotNotation == camelot

                    CamelotSegment(
                        camelot: camelot,
                        angle: angle,
                        distance: distance,
                        center: center,
                        trackCount: tracksAtPosition.count,
                        isSelected: isSelected,
                        isMajor: isMajor
                    )
                }

                // Center label
                VStack(spacing: 4) {
                    Text("CAMELOT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.tertiaryTextColor)
                    Text("WHEEL")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(themeManager.tertiaryTextColor)
                    Text("\(tracks.count)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.accentColor)
                    Text("tracks")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct CamelotSegment: View {
    let camelot: String
    let angle: Double
    let distance: CGFloat
    let center: CGPoint
    let trackCount: Int
    let isSelected: Bool
    let isMajor: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let radian = angle * .pi / 180
        let x = center.x + distance * cos(radian)
        let y = center.y + distance * sin(radian)

        ZStack {
            // Dot indicator
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)

            // Camelot label
            Text(camelot)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(labelColor)
        }
        .position(x: x, y: y)
    }

    private var dotSize: CGFloat {
        if trackCount == 0 { return 4 }
        if isSelected { return 16 }
        return min(8 + CGFloat(trackCount) * 2, 20)
    }

    private var fontSize: CGFloat {
        isSelected ? 11 : (trackCount > 0 ? 9 : 7)
    }

    private var dotColor: Color {
        if isSelected { return themeManager.accentColor }
        if trackCount > 0 { return themeManager.accentColor.opacity(0.6) }
        return themeManager.surfaceColor
    }

    private var labelColor: Color {
        if isSelected { return themeManager.accentColor }
        if trackCount > 0 { return themeManager.textColor }
        return themeManager.tertiaryTextColor
    }
}
