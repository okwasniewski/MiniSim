//
//  NSMenuItem+ImageInit.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit

extension NSMenuItem {
    convenience init(
        title: String,
        action: Selector?,
        keyEquivalent: String,
        type: DeviceMenuItem,
        image: NSImage? = nil
    ) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)

        if let image {
            self.image = image
        } else {
            if title.contains("Vision") {
                self.image = NSImage(named: "vision_os")
                self.image?.isTemplate = true
                self.image?.size = NSSize(width: 15, height: 8.5)
            } else {
                let imageName = self.getSystemImageFromName(name: title)
                self.image = NSImage(systemSymbolName: imageName, accessibilityDescription: title)
            }
        }

        self.tag = type.rawValue
    }

    private func getSystemImageFromName(name: String) -> String {
        if name.contains("Apple TV") {
            return "appletv.fill"
        }

        if name.contains("iPad") || name.contains("Tablet") {
            return "ipad.landscape"
        }

        if name.contains("Watch") {
            return "applewatch"
        }

        if name.contains("TV") {
            return "tv"
        }

        return "iphone"
    }
}
