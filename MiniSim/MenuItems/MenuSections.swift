//
//  MenuSections.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 27/01/2023.
//

import Cocoa

enum MenuSections: Int, CaseIterable {
    case iOSHeader = 100
    case separator1 = 1
    case androidHeader = 101
    
    case separator2 = 2
    case clearDerrivedData = 119
    case preferences = 120
    case quit = 121
    
    var menuItem: NSMenuItem {
        var item: NSMenuItem!
        switch self {
        case .separator1, .separator2:
            item = NSMenuItem.separator()
        case .iOSHeader, .androidHeader:
            if #available(macOS 14.0, *) {
                item = NSMenuItem.sectionHeader(title: "")
            } else {
                item = NSMenuItem()
            }
        default:
            item = NSMenuItem()
        }
        
        item.tag = rawValue
        item.keyEquivalent = keyEquivalent
        item.title = title
        item.toolTip = title
        return item
    }
    
    var attachItem: Bool {
        switch self {
        case .iOSHeader, .separator1, .clearDerrivedData:
            return UserDefaults.standard.enableiOSSimulators
        case .androidHeader, .separator2:
            return UserDefaults.standard.enableAndroidEmulators
        default:
            return true
        }
    }
    
    var keyEquivalent: String {
        switch self {
        case .quit:
            return "q"
        case .preferences:
            return ","
        default:
            return ""
        }
    }
    
    var title: String {
        switch self {
        case .iOSHeader:
            return NSLocalizedString("iOS Simulator", comment: "")
        case .androidHeader:
            return NSLocalizedString("Android Simulator", comment: "")
        case .quit:
            return NSLocalizedString("Quit", comment: "")
        case .preferences:
            return NSLocalizedString("Preferences", comment: "")
        case .clearDerrivedData:
            return NSLocalizedString("Clear Xcode Derived Data", comment: "")
        default:
            return ""
        }
    }
}
