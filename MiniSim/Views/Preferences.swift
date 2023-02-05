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
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "Hotkey:") {
                KeyboardShortcuts.Recorder("", name: .toggleMiniSim)
                Text("Global shortcut to open the application \nDefault: ⌥⇧E")
                    .padding(.leading, 15)
                    .font(.caption)
                    .opacity(0.3)
                
                Button("Clear cache") {
                    resetDefaults()
                }
                Text("This clears data saved in cache.")
                    .padding(.leading, 15)
                    .font(.caption)
                    .opacity(0.3)
                
                Divider()
                LaunchAtLogin.Toggle("Launch at login")
                
            }
        }
    }
    
    func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}
