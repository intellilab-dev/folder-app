//
//  SettingsView.swift
//  Folder
//
//  App settings and preferences panel
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 10)

            Divider()

            // Settings Form
            Form {
                // View Settings
                Section(header: Text("View").font(.headline)) {
                    // Default View Mode
                    Picker("Default View Mode:", selection: $settingsManager.settings.defaultViewMode) {
                        Text("Icon Grid").tag(AppSettings.DisplayMode.iconGrid)
                        Text("List").tag(AppSettings.DisplayMode.list)
                    }
                    .pickerStyle(.radioGroup)

                    // Icon Size Slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon Size (Grid View): \(settingsManager.settings.iconSize)px")
                            .font(.subheadline)

                        Slider(
                            value: Binding(
                                get: { Double(settingsManager.settings.iconSize) },
                                set: { settingsManager.settings.iconSize = Int($0) }
                            ),
                            in: 32...128,
                            step: 8
                        )
                    }
                }

                // File Display Settings
                Section(header: Text("Files").font(.headline)) {
                    Toggle("Show Hidden Files", isOn: $settingsManager.settings.showHiddenFiles)
                }

                // Sidebar Visibility
                Section(header: Text("Sidebar").font(.headline)) {
                    Toggle("Show Favorites Section", isOn: $settingsManager.settings.showFavoritesSection)
                    Toggle("Show Recent Section", isOn: $settingsManager.settings.showRecentSection)
                    Toggle("Show Color Tags Section", isOn: $settingsManager.settings.showColorTagsSection)
                }

                // Appearance Settings
                Section(header: Text("Appearance").font(.headline)) {
                    Picker("Theme:", selection: $settingsManager.settings.theme) {
                        Text("Light").tag(AppSettings.Theme.light)
                        Text("Dark").tag(AppSettings.Theme.dark)
                        Text("System").tag(AppSettings.Theme.system)
                    }
                    .pickerStyle(.radioGroup)
                }

                // Keyboard Shortcuts
                Section(header: Text("Keyboard Shortcuts").font(.headline)) {
                    Toggle("Enable Search (Cmd+F)", isOn: $settingsManager.settings.keyboardShortcuts.searchEnabled)

                    Toggle("Enable Folder Navigation", isOn: $settingsManager.settings.keyboardShortcuts.navigationEnabled)

                    if settingsManager.settings.keyboardShortcuts.navigationEnabled {
                        Picker("Navigation Modifier:", selection: $settingsManager.settings.keyboardShortcuts.navigationModifier) {
                            Text("Control (⌃)").tag(KeyboardShortcuts.KeyModifier.control)
                            Text("Command (⌘)").tag(KeyboardShortcuts.KeyModifier.command)
                            Text("Option (⌥)").tag(KeyboardShortcuts.KeyModifier.option)
                        }
                        .pickerStyle(.radioGroup)
                        .padding(.leading, 20)

                        Text("Use \(settingsManager.settings.keyboardShortcuts.navigationModifier.rawValue)+Arrow keys to navigate folders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }

                    Toggle("Enable Arrow Keys", isOn: $settingsManager.settings.keyboardShortcuts.arrowKeysEnabled)

                    if settingsManager.settings.keyboardShortcuts.arrowKeysEnabled {
                        Text("Use Arrow keys (without modifiers) to navigate between files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }

                // Global Hotkey
                Section(header: Text("Global Hotkey").font(.headline)) {
                    Toggle("Enable Global Hotkey", isOn: $settingsManager.settings.globalHotkey.enabled)

                    if settingsManager.settings.globalHotkey.enabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Hotkey: \(settingsManager.settings.globalHotkey.displayString)")
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Text("Activates Folder from anywhere on your system")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 20)
                    }
                }

                // System Settings
                Section(header: Text("System").font(.headline)) {
                    Toggle("Show Menu Bar Icon", isOn: $settingsManager.settings.showMenuBarIcon)

                    Toggle("Launch at Login", isOn: $settingsManager.settings.launchAtLogin)

                    Text("Add Folder to Login Items in System Preferences > Users & Groups to launch at login")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer with buttons
            HStack {
                Button("Reset to Defaults") {
                    settingsManager.reset()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 550, height: 700)
    }
}
