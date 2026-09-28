import SwiftUI

struct TagWritingSettingsView: View {
    @Binding var preferences: TagWritingPreferences
    let previewMetadata: TrackMetadata
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    private let engine = TemplateEngine()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TAG WRITING SETTINGS")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(themeManager.textColor)

            HStack {
                Text("Profile")
                Picker("Profile", selection: $preferences.profile) {
                    ForEach(TagWritingProfileID.allCases) { profile in
                        Text(profile.displayName).tag(profile)
                    }
                }
                Button("Apply Profile") {
                    preferences.mappings = TagWritingPreferences.profileMappings(preferences.profile)
                }
            }

            Toggle("Create backup before writing", isOn: $preferences.createBackup)
            Toggle("Dry-run only", isOn: $preferences.dryRunOnly)
            Toggle("Force overwrite non-empty target fields", isOn: $preferences.forceOverwrite)

            Stepper("Max concurrent writes: \(preferences.maxConcurrentWrites)", value: $preferences.maxConcurrentWrites, in: 1...8)

            Divider()

            Text("What will be written")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
            ForEach(Array(preferences.mappings.enumerated()), id: \.offset) { index, mapping in
                VStack(alignment: .leading) {
                    Text("\(targetLabel(mapping.target)) [\(mapping.mode.rawValue)]")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                    Text(engine.render(template: mapping.template, metadata: previewMetadata, notationOverride: mapping.notation, options: WriteOptions(trimWhitespace: true, mappings: preferences.mappings)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(themeManager.secondaryTextColor)

                    HStack {
                        TextField("Template", text: Binding(
                            get: { preferences.mappings[index].template },
                            set: { preferences.mappings[index].template = $0 }
                        ))
                        Picker("Mode", selection: Binding(
                            get: { preferences.mappings[index].mode },
                            set: { preferences.mappings[index].mode = $0 }
                        )) {
                            ForEach(WriteMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .frame(width: 130)
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 760, height: 620)
        .background(themeManager.backgroundColor)
    }

    private func targetLabel(_ target: TagTarget) -> String {
        switch target {
        case .comment: return "COMM"
        case .tkey: return "TKEY"
        case .grouping: return "TIT1 (Grouping)"
        case .title: return "TIT2 (Title)"
        case .bpm: return "TBPM"
        case .artist: return "TPE1"
        case .genre: return "TCON"
        case .year: return "TYER"
        case .txxx(let descriptor): return "TXXX:\(descriptor)"
        }
    }
}
