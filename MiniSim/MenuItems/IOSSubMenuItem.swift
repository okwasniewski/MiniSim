//
//  iOSSubMenuItem.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 08/02/2023.
//

import Cocoa

enum IOSSubMenuItem: Int, CaseIterable, SubMenuItem {
    
    case copyName = 100
    case copyUDID
    case separator
    case deleteSim
    case customCommand = 200
    
    var needBootedDevice: Bool { false }
    
    var bootsDevice: Bool { false }
    
    var tag: Int { self.rawValue }
    
    var isSeparator: Bool { self == .separator }

    var title: String {
        switch self {
        case .copyName:
            return NSLocalizedString("Copy name", comment: "")
        case .copyUDID:
            return NSLocalizedString("Copy UDID", comment: "")
        case .deleteSim:
            return NSLocalizedString("Delete simulator", comment: "")
        default:
            return ""
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
        default:
            return nil
        }
    }
    
    var CommandItem: Command? {
        if self == .separator || self == .customCommand {
            return nil
        }
        
        // `needBootedDevice` is not supported on iOS.
        return Command(name: self.title, command: "", icon: "", platform: Platform.ios, needBootedDevice: false, tag: self.rawValue)
    }
    
}
