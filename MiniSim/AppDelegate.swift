//
//  AppDelegate.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Cocoa
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var miniSim: MiniSim!
    private var hotkey: HotKey!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        miniSim = MiniSim()
        hotkey = HotKey(key: .e, modifiers: [.option, .shift])
        
        self.hotkey.keyUpHandler = {
            self.miniSim.open()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        miniSim.open()
        return true
    }
}
