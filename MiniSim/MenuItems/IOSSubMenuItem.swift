//
//  iOSSubMenuItem.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 08/02/2023.
//

import Cocoa

enum IOSSubMenuItem: Int, CaseIterable {
    
    case copyName = 100
    case copyUDID = 101
    case deleteSim = 102
    
    var menuItem: NSMenuItem {
        let item = NSMenuItem()
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
        case .copyUDID:
            return NSLocalizedString("Copy UDID", comment: "")
        case .deleteSim:
            return NSLocalizedString("Delete simulator", comment: "")
        }
    }
    
    var image: NSImage? {
        switch self {
        case .copyName:
            return NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Copy name")
        case .copyUDID:
            return NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy UDID")
        case .deleteSim:
            return NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete simulator")
        }
        
    }
}
