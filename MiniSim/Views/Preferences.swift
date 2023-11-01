//
//  Preferences.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import KeyboardShortcuts
import LaunchAtLogin
import Preferences
import SwiftUI

struct Preferences: View {
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "Hotkey:") {
                KeyboardShortcuts.Recorder("", name: .toggleMiniSim)
                Text("Global shortcut to open the application \nDefault: ⌥⇧E")
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
        .frame(minWidth: 650, minHeight: 450)
    }

    func resetDefaults() {
        let shouldReset = NSAlert.showQuestionDialog(
            title: "Are you sure?",
            message: "This will reset cache and quit the app."
        )
        if shouldReset {
            let defaults = UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                defaults.removeObject(forKey: key)
            }
            NSApp.terminate(nil)
        }
    }
}
