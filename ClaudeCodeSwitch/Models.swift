//
//  Models.swift
//  ClaudeCodeSwitch
//

import Foundation

struct EnvPreset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var env: [String: String]
    var isActive: Bool = false

    var displayURL: String {
        env["ANTHROPIC_BASE_URL"] ?? "No URL"
    }
}

struct ClaudeSettings: Codable {
    var env: [String: String]?
    var includeCoAuthoredBy: Bool?
    var permissions: Permissions?
    var hooks: [String: [HookGroup]]?
    var enabledPlugins: [String: Bool]?
    var alwaysThinkingEnabled: Bool?

    struct Permissions: Codable {
        var allow: [String]?
        var deny: [String]?
    }

    struct HookGroup: Codable {
        var hooks: [Hook]?
    }

    struct Hook: Codable {
        var type: String?
        var command: String?
    }
}

class SettingsManager: ObservableObject {
    @Published var presets: [EnvPreset] = []
    @Published var errorMessage: String?

    private let settingsPath: String
    private let presetsPath: String

    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        self.settingsPath = "\(homeDir)/.claude/settings.json"
        self.presetsPath = "\(homeDir)/.claude/env_presets.json"

        loadPresets()
        loadCurrentEnvAsDefault()
    }

    private func loadCurrentEnvAsDefault() {
        guard let settings = readSettings() else { return }
        guard let env = settings.env else { return }

        // Check if we already have a preset with this env
        let existingActive = presets.first { $0.isActive }
        if existingActive == nil {
            // Create default preset from current settings
            let defaultPreset = EnvPreset(
                name: "Default",
                env: env,
                isActive: true
            )

            // Check if Default already exists
            if let index = presets.firstIndex(where: { $0.name == "Default" }) {
                presets[index].env = env
                presets[index].isActive = true
            } else {
                presets.insert(defaultPreset, at: 0)
            }
            savePresets()
        }
    }

    func readSettings() -> ClaudeSettings? {
        guard let data = FileManager.default.contents(atPath: settingsPath) else {
            errorMessage = "Cannot read settings.json"
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ClaudeSettings.self, from: data)
        } catch {
            errorMessage = "Failed to parse settings: \(error.localizedDescription)"
            return nil
        }
    }

    func writeSettings(_ settings: ClaudeSettings) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: URL(fileURLWithPath: settingsPath))
            return true
        } catch {
            errorMessage = "Failed to write settings: \(error.localizedDescription)"
            return false
        }
    }

    func activatePreset(_ preset: EnvPreset) {
        guard var settings = readSettings() else { return }

        settings.env = preset.env

        if writeSettings(settings) {
            // Update active states
            for i in presets.indices {
                presets[i].isActive = (presets[i].id == preset.id)
            }
            savePresets()
        }
    }

    func addPreset(_ preset: EnvPreset) {
        presets.append(preset)
        savePresets()
    }

    func deletePreset(_ preset: EnvPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }

    func updatePreset(_ preset: EnvPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            savePresets()
        }
    }

    private func loadPresets() {
        guard let data = FileManager.default.contents(atPath: presetsPath) else {
            return
        }

        do {
            presets = try JSONDecoder().decode([EnvPreset].self, from: data)
        } catch {
            print("Failed to load presets: \(error)")
        }
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: URL(fileURLWithPath: presetsPath))
        } catch {
            print("Failed to save presets: \(error)")
        }
    }
}
