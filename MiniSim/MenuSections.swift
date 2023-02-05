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
    case preferences = 120
    case quit = 121
    
    var menuItem: NSMenuItem {
        var item: NSMenuItem!
        switch self {
        case .separator1, .separator2:
            item = NSMenuItem.separator()
        default:
            item = NSMenuItem()
        }
        
        item.tag = rawValue
        item.keyEquivalent = keyEquivalent
        item.title = title
        item.toolTip = title
        return item
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
        default:
            return ""
        }
    }
}
