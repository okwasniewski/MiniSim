//
//  AndroidSubMenuItem.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 07/02/2023.
//

import Cocoa

enum AndroidSubMenuItem: Int, CaseIterable {
    
    case copyName = 100
    case copyAdbId = 101
    case separator = 102
    case coldBootAndroid = 103
    case androidNoAudio = 104
    case toggleA11yAndroid = 105
    case pasteToEmulator = 106
    case customCommand = 1000
    
    var needBootedDevice: Bool {
        switch self {
        case .copyAdbId, .toggleA11yAndroid, .pasteToEmulator:
            return true
        default:
            return false
        }
    }
    
    var bootsDevice: Bool {
        switch self {
        case .androidNoAudio, .coldBootAndroid:
            return true
        default:
            return false
        }
    }
    
    var menuItem: NSMenuItem {
        let item = self == .separator ? NSMenuItem.separator() : NSMenuItem()
        item.tag = rawValue
        item.image = image
        item.title = title
        item.toolTip = title
        return item
    }
    
    var title: String {
        switch self {
        case .copyName:
            return NSLocalizedString("Copy name", comment: "")
        case .copyAdbId:
            return NSLocalizedString("Copy ID", comment: "")
        case .androidNoAudio:
            return NSLocalizedString("Run without audio", comment: "")
        case .coldBootAndroid:
            return NSLocalizedString("Cold boot", comment: "")
        case .toggleA11yAndroid:
            return NSLocalizedString("Toggle accessibility", comment: "")
        case .pasteToEmulator:
            return NSLocalizedString("Paste clipboard to emulator", comment: "")
        default:
            return ""
        }
    }
    
    var image: NSImage? {
        switch self {
        case .copyName:
            return NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Copy name")
        case .copyAdbId:
            return NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy ID")
        case .androidNoAudio:
            return NSImage(systemSymbolName: "speaker.slash.fill", accessibilityDescription: "Run without audio")
        case .coldBootAndroid:
            return NSImage(systemSymbolName: "sunrise.fill", accessibilityDescription: "Cold boot")
        case .toggleA11yAndroid:
            return NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: "Toggle accessibility")
        case .pasteToEmulator:
            return NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard")
        default:
            return NSImage()
        }
    }
    
    var CommandItem: Command? {
        if self == .separator || self == .customCommand {
            return nil
        }
        return Command(name: self.title, command: "", icon: "", platform: Platform.android, needBootedDevice: needBootedDevice, bootsDevice: self.bootsDevice, tag: self.rawValue)
    }
}
