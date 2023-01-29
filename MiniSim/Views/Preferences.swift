//
//  Preferences.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import SwiftUI
import Preferences
import KeyboardShortcuts

struct Preferences: View {
    var body: some View {
        Settings.Container(contentWidth: 350) {
            Settings.Section(title: "Hotkey:") {
                KeyboardShortcuts.Recorder("", name: .toggleMiniSim)
                Text("Global shortcut to open the application \nDefault: ⌥⇧E")
                    .padding(.leading, 15)
                    .font(.caption)
                    .opacity(0.3)
            }
        }
    }
}
