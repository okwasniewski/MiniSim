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
            return NSImage(systemSymbolName: "sunrise.fill", accessibilityDescription: "Run without audio")
        case .coldBootAndroid:
            return NSImage(systemSymbolName: "speaker.slash.fill", accessibilityDescription: "Cold boot")
        case .toggleA11yAndroid:
            return NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: "Toggle accessibility")
        default:
            return NSImage()
        }
    }
}
