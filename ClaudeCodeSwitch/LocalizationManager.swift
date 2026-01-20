//
//  LocalizationManager.swift
//  ClaudeCodeSwitch
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }

    static func fromSystemLanguage() -> AppLanguage {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if preferredLanguage.hasPrefix("zh") {
            return .chinese
        }
        return .english
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // First launch: detect system language
            self.currentLanguage = AppLanguage.fromSystemLanguage()
            UserDefaults.standard.set(self.currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
}

// MARK: - Localized Strings
struct L10n {
    static var shared: L10n {
        L10n(language: LocalizationManager.shared.currentLanguage)
    }

    let language: AppLanguage

    // App Title
    var appTitle: String {
        language == .english ? "Claude Code Switch" : "Claude Code Switch"
    }

    // Buttons
    var enable: String {
        language == .english ? "Enable" : "启用"
    }

    var inUse: String {
        language == .english ? "In Use" : "使用中"
    }

    var currentlyUsing: String {
        language == .english ? "Current" : "当前使用"
    }

    var edit: String {
        language == .english ? "Edit" : "编辑"
    }

    var delete: String {
        language == .english ? "Delete" : "删除"
    }

    var cancel: String {
        language == .english ? "Cancel" : "取消"
    }

    var save: String {
        language == .english ? "Save" : "保存"
    }

    var add: String {
        language == .english ? "Add" : "添加"
    }

    // Preset Views
    var addNewPreset: String {
        language == .english ? "Add New Preset" : "添加新预设"
    }

    var editPreset: String {
        language == .english ? "Edit Preset" : "编辑预设"
    }

    var name: String {
        language == .english ? "Name" : "名称"
    }

    var enterPresetName: String {
        language == .english ? "Enter preset name" : "输入预设名称"
    }

    var envJson: String {
        language == .english ? "ENV (JSON)" : "环境变量 (JSON)"
    }

    var noUrl: String {
        language == .english ? "No URL" : "无URL"
    }

    // Settings
    var settings: String {
        language == .english ? "Settings" : "设置"
    }

    var language_: String {
        language == .english ? "Language" : "语言"
    }

    var done: String {
        language == .english ? "Done" : "完成"
    }

    // Tooltips
    var addNewPresetTooltip: String {
        language == .english ? "Add new preset" : "添加新预设"
    }

    var settingsTooltip: String {
        language == .english ? "Settings" : "设置"
    }
}
