//
//  Preferences.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import KeyboardShortcuts
import LaunchAtLogin
import Settings
import SwiftUI

struct Preferences: View {
    @State var menuImageSelected: String = "iphone"
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
            Settings.Section(title: "Icon:") {
                Picker("", selection: $menuImageSelected) {
                    ForEach(MenuImage.allCases, id: \.self) { image in
                        Image(nsImage: NSImage(imageLiteralResourceName: image.rawValue))
                            .tag(image.rawValue)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .onChange(of: menuImageSelected) { _ in
                    UserDefaults.standard.menuImage = menuImageSelected
                }
                Text("The icon displayed in the Menu Bar.")
                    .descriptionText()
            }
            Settings.Section(title: "Preferred Terminal:") {
                  Picker("", selection: $preferedTerminal) {
                    let availableTerminal = Terminal.allCases.filter { $0.isAvailable() }
                    ForEach(availableTerminal, id: \.self) { terminal in
                      HStack {
                        Image(nsImage: terminal.getAppIcon() ?? NSImage())
                        Text(terminal.rawValue)
                      }
                      .tag(terminal.rawValue)
                    }
                  }
                  .onChange(of: preferedTerminal) { _ in
                      UserDefaults.standard.setValue(
                          preferedTerminal.rawValue, forKey: UserDefaults.Keys.preferedTerminal
                      )
                  }
                  Text("Users can choose their preferred terminal from the above supported terminal list")
                      .descriptionText()
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
        .onAppear {
            MenuImage.allCases.forEach { image in
                if UserDefaults.standard.menuImage == image.rawValue {
                    menuImageSelected = image.rawValue
                }
            }
        }
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
