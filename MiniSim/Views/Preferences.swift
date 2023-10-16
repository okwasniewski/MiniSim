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
    var menuImages = [ "menu_icon_1", "menu_icon_2", "menu_icon_3" ]
    @State var menuImageSelected = 0
    
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "Icon:") {
                Picker("", selection: $menuImageSelected) {
                    ForEach(0 ..< menuImages.count, id: \.self) { image in
                        Image(menuImages[image])
                            .renderingMode(.template)
                            .tag(image)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: menuImageSelected) { _ in
                    UserDefaults.standard.menuImage = menuImages[menuImageSelected]
                }
                Text("The icon displayed in the Menu Bar.")
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
            for image in 0 ..< menuImages.count {
                if (UserDefaults.standard.menuImage == menuImages[image]) {
                    menuImageSelected = image
                }
            }
        }
    }
    
    func resetDefaults() {
        let shouldReset = NSAlert.showQuestionDialog(title: "Are you sure?", message: "This will reset cache and quit the app.")
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
