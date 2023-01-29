//
//  Preferences.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import SwiftUI
import Preferences

struct Preferences: View {
    var body: some View {
        Settings.Container(contentWidth: 450) {
            Settings.Section(title: "Section Title") {
                Text("1")
            }
        }
    }
}
