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
    @State private var preferedTerminal: Terminal

    init() {
           let userPrefered = UserDefaults.standard.preferedTerminal
           if let terminal = Terminal(rawValue: userPrefered ?? Terminal.terminal.rawValue) {
               preferedTerminal = terminal
           } else {
               preferedTerminal = Terminal.terminal
           }
    }

    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "Preferred Terminal:") {
                Picker("", selection: $preferedTerminal) {
                    ForEach(Terminal.allCases, id: \.self) { terminal in
                        Text(terminal.rawValue)
                    }
                }
                .onChange(of: preferedTerminal) { _ in
                    UserDefaults.standard.setValue(preferedTerminal.rawValue, forKey: UserDefaults.Keys.preferedTerminal)
                }
                Text("Users can choose their preferred terminal from the above supported terminal list").descriptionText()
            }
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
