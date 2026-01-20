//
//  ContentView.swift
//  ClaudeCodeSwitch
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = SettingsManager()
    @State private var showingAddSheet = false
    @State private var editingPreset: EnvPreset?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(showingAddSheet: $showingAddSheet)

            Divider()
                .background(Color.gray.opacity(0.3))

            // Preset List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(manager.presets) { preset in
                        PresetRow(
                            preset: preset,
                            onActivate: {
                                manager.activatePreset(preset)
                            },
                            onEdit: {
                                editingPreset = preset
                            },
                            onDelete: {
                                manager.deletePreset(preset)
                            }
                        )
                    }
                }
                .padding(20)
            }

            Spacer()

            // Error message
            if let error = manager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            AddPresetView(manager: manager)
        }
        .sheet(item: $editingPreset) { preset in
            EditPresetView(manager: manager, preset: preset)
        }
    }
}

struct HeaderView: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        HStack {
            Text("Claude Code Switch")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Spacer()

            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .help("Add new preset")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct PresetRow: View {
    let preset: EnvPreset
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(String(preset.name.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Name and URL
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if preset.isActive {
                        Text("当前使用")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text(preset.displayURL)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                if preset.isActive {
                    // 使用中 button (disabled state)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                        Text("使用中")
                            .font(.callout)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.secondary)
                    .cornerRadius(6)
                } else {
                    // 启用 button
                    Button(action: onActivate) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text("启用")
                                .font(.callout)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Edit")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(preset.isActive ? Color.blue.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(preset.isActive ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct AddPresetView: View {
    @ObservedObject var manager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var envJson = ""
    @State private var parseError: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Preset")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Enter preset name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ENV (JSON)")
                    .font(.headline)

                TextEditor(text: $envJson)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            if let error = parseError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Add") {
                    if let env = parseEnvJson(envJson) {
                        let preset = EnvPreset(name: name, env: env)
                        manager.addPreset(preset)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 500)
        .onAppear {
            // Load default env from current settings
            if let settings = manager.readSettings(),
               let env = settings.env,
               let data = try? JSONSerialization.data(withJSONObject: env, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: data, encoding: .utf8) {
                envJson = jsonString
            }
        }
    }

    private func parseEnvJson(_ json: String) -> [String: String]? {
        guard let data = json.data(using: .utf8) else {
            parseError = "Invalid string encoding"
            return nil
        }
        do {
            let dict = try JSONDecoder().decode([String: String].self, from: data)
            parseError = nil
            return dict
        } catch {
            parseError = "JSON parse error: \(error.localizedDescription)"
            return nil
        }
    }
}

struct EditPresetView: View {
    @ObservedObject var manager: SettingsManager
    let preset: EnvPreset
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var envJson: String = ""
    @State private var parseError: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Preset")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Enter preset name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ENV (JSON)")
                    .font(.headline)

                TextEditor(text: $envJson)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            if let error = parseError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    if let env = parseEnvJson(envJson) {
                        var updated = preset
                        updated.name = name
                        updated.env = env
                        manager.updatePreset(updated)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 500)
        .onAppear {
            name = preset.name
            // Convert env dict to pretty JSON
            if let data = try? JSONSerialization.data(withJSONObject: preset.env, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: data, encoding: .utf8) {
                envJson = jsonString
            }
        }
    }

    private func parseEnvJson(_ json: String) -> [String: String]? {
        guard let data = json.data(using: .utf8) else {
            parseError = "Invalid string encoding"
            return nil
        }
        do {
            let dict = try JSONDecoder().decode([String: String].self, from: data)
            parseError = nil
            return dict
        } catch {
            parseError = "JSON parse error: \(error.localizedDescription)"
            return nil
        }
    }
}

#Preview {
    ContentView()
}
