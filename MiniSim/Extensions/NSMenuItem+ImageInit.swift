//
//  NSMenuItem+ImageInit.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit

extension NSMenuItem {
    convenience init(title: String, action: Selector?, keyEquivalent: String, systemSymbolName: String) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: title)
    }
}

