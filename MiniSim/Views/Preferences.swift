//
//  Preferences.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import SwiftUI
import Preferences
import KeyboardShortcuts
import LaunchAtLogin

struct Preferences: View {
    @State private var hasA11yAccess = false
    
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "Hotkey:") {
                KeyboardShortcuts.Recorder("", name: .toggleMiniSim)
                Text("Global shortcut to open the application \nDefault: ⌥⇧E")
                    .descriptionText()
            }
            Settings.Section(title: "Accessibility:") {
                Button("Request access") {
                    hasA11yAccess = AccessibilityElement.hasA11yAccess()
                }
                .disabled(hasA11yAccess)
                .onAppear {
                    hasA11yAccess = AccessibilityElement.hasA11yAccess(prompt: false)
                }
                Text("Accessibility API is used to focus simulators. \(hasA11yAccess ? "App currently has access to accessibility." : "")")
                    .descriptionText()
            }
            Settings.Section(title: "Cache:") {
                Button("Clear cache") {
                    resetDefaults()
                }
                Text("This clears data saved in cache. \nFor example: developer tool paths.")
                    .descriptionText()
            }
            Settings.Section(title: "") {
                Divider()
                LaunchAtLogin.Toggle("Launch at login")
            }
        }
        .frame(minHeight: 320)
    }
    
    func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}
