//
//  Menu.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import AppKit
import KeyboardShortcuts

class Menu: NSMenu, NSMenuDelegate {
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: "MiniSim")
        self.delegate = self
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        KeyboardShortcuts.disable(.toggleMiniSim)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.toggleMiniSim)
    }
}
