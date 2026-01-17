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
        deviceFamily: DeviceFamily? = nil,
        image: NSImage? = nil
    ) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)

        if let image {
            self.image = image
        } else if let deviceFamily {
            self.image = NSImage(
                systemSymbolName: deviceFamily.iconName,
                accessibilityDescription: title
            )
        } else {
            let imageName = self.getSystemImageFromName(name: title)
            self.image = NSImage(systemSymbolName: imageName, accessibilityDescription: title)
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

        if name.contains("Apple Watch") {
            return "applewatch"
        }

        if name.contains("TV") {
            return "tv"
        }

        return "iphone"
    }
}
