//
//  AppDelegate.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Cocoa
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    private var miniSim: MiniSim!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        miniSim = MiniSim()

        KeyboardShortcuts.onKeyUp(for: .toggleMiniSim) {
            self.miniSim.open()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        true
    }
}
