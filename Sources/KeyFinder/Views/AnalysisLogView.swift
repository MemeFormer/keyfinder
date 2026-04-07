import SwiftUI

struct AnalysisLogView: View {
    @ObservedObject var model: AudioAnalysisModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var autoScroll = true
    @State private var filterType: AnalysisLogEntry.LogType? = nil

    var filteredLog: [AnalysisLogEntry] {
        if let filter = filterType {
            return model.analysisLog.filter { $0.type == filter }
        }
        return model.analysisLog
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ANALYSIS LOG")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Text("\(filteredLog.count) entries")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(themeManager.tertiaryTextColor)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.surfaceColor)

            // Filter buttons
            HStack(spacing: 8) {
                FilterButton(title: "All", isSelected: filterType == nil) {
                    filterType = nil
                }

                FilterButton(title: "Info", isSelected: filterType == .info, color: .blue) {
                    filterType = filterType == .info ? nil : .info
                }

                FilterButton(title: "Success", isSelected: filterType == .success, color: .green) {
                    filterType = filterType == .success ? nil : .success
                }

                FilterButton(title: "Warning", isSelected: filterType == .warning, color: .orange) {
                    filterType = filterType == .warning ? nil : .warning
                }

                FilterButton(title: "Error", isSelected: filterType == .error, color: .red) {
                    filterType = filterType == .error ? nil : .error
                }

                Spacer()

                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(themeManager.tertiaryTextColor)

                Button(action: { model.clearLog() }) {
                    Text("Clear")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(themeManager.surfaceColor.opacity(0.5))

            // Log entries
            if filteredLog.isEmpty {
                VStack {
                    Spacer()
                    Text("No log entries yet")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(themeManager.tertiaryTextColor)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredLog) { entry in
                                LogEntryRow(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .onChange(of: model.analysisLog.count) { _ in
                        if autoScroll, let lastEntry = filteredLog.last {
                            withAnimation {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Status bar
            HStack {
                let infoCount = model.analysisLog.filter { $0.type == .info }.count
                let successCount = model.analysisLog.filter { $0.type == .success }.count
                let warningCount = model.analysisLog.filter { $0.type == .warning }.count
                let errorCount = model.analysisLog.filter { $0.type == .error }.count

                Label("\(infoCount) Info", systemImage: "info.circle")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(themeManager.tertiaryTextColor)

                Divider()
                    .frame(height: 10)

                Label("\(successCount) Success", systemImage: "checkmark.circle")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.green)

                Divider()
                    .frame(height: 10)

                Label("\(warningCount) Warning", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange)

                Divider()
                    .frame(height: 10)

                Label("\(errorCount) Error", systemImage: "xmark.circle")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.red)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(themeManager.surfaceColor)
        }
        .background(themeManager.backgroundColor)
        .onExitCommand {
            dismiss()
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .gray
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? color : color.opacity(0.2))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct LogEntryRow: View {
    let entry: AnalysisLogEntry
    @EnvironmentObject var themeManager: ThemeManager

    var typeColor: Color {
        switch entry.type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        case .progress: return .purple
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.formattedTime)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(themeManager.tertiaryTextColor)
                .frame(width: 60, alignment: .leading)

            Text(entry.type.rawValue)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(typeColor)
                .frame(width: 50, alignment: .leading)

            Text(entry.message)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(themeManager.textColor)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(typeColor.opacity(0.05))
        .cornerRadius(2)
    }
}
