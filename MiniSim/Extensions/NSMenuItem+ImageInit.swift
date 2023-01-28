//
//  NSMenuItem+ImageInit.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit

extension NSMenuItem {
    convenience init(title: String, action: Selector?, keyEquivalent: String, type: MenuItemType, showImage: Bool = true) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        if (showImage) {
            let imageName = DeviceService.getSystemImageFromName(name: title)
            self.image = NSImage(systemSymbolName: imageName, accessibilityDescription: title)
        }
        self.tag = type.rawValue
    }
}

