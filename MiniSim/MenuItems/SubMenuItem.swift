//
//  SubMenuItem.swift
//  MiniSim
//
//  Created by Anton Kolchunov on 11.10.23.
//

import Cocoa
import Foundation

protocol SubMenuItem { }

protocol SubMenuActionItem: SubMenuItem {
    var title: String { get }
    var tag: Int { get }
    var needBootedDevice: Bool { get }
    var bootsDevice: Bool  { get }
    var image: NSImage? { get }
}

enum SubMenuItems {
    enum Tags: Int {
        case copyName = 100
        case copyID
        case coldBoot
        case noAudio
        case toggleA11y
        case paste
        case delete
        case customCommand = 200
    }
    
    struct Separator: SubMenuItem { }
    
    struct CopyName: SubMenuActionItem {
        let title = NSLocalizedString("Copy name", comment: "")
        let tag = Tags.copyName.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "square.and.arrow.up",
            accessibilityDescription: "Copy name"
        )
    }
    
    struct CopyID: SubMenuActionItem {
        let title = NSLocalizedString("Copy ID", comment: "")
        let tag = Tags.copyID.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: "Copy ID"
        )
    }
    
    struct CopyUDID: SubMenuActionItem {
        let title = NSLocalizedString("Copy UDID", comment: "")
        let tag = Tags.copyID.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: "Copy UDID"
        )
    }
    
    struct ColdBoot: SubMenuActionItem {
        let title = NSLocalizedString("Cold boot", comment: "")
        let tag = Tags.coldBoot.rawValue
        let bootsDevice = true
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "sunrise.fill",
            accessibilityDescription: "Cold boot"
        )
    }
    
    struct NoAudio: SubMenuActionItem {
        let title = NSLocalizedString("Run without audio", comment: "")
        let tag = Tags.noAudio.rawValue
        let bootsDevice = true
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "speaker.slash.fill",
            accessibilityDescription: "Run without audio"
        )
    }
    
    struct ToggleA11y: SubMenuActionItem {
        let title = NSLocalizedString("Toggle accessibility", comment: "")
        let tag = Tags.toggleA11y.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "figure.walk.circle.fill",
            accessibilityDescription: "Toggle accessibility"
        )
    }
    
    struct Paste: SubMenuActionItem {
        let title = NSLocalizedString("Paste clipboard to device", comment: "")
        let tag = Tags.paste.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "keyboard",
            accessibilityDescription: "Keyboard"
        )
    }
    
    struct Delete: SubMenuActionItem {
        let title = NSLocalizedString("Delete simulator", comment: "")
        let tag = Tags.delete.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "trash",
            accessibilityDescription: "Delete simulator"
        )
    }
}

extension SubMenuItems {
    static var android: [SubMenuItem] = [
        CopyName(),
        CopyID(),
        
        Separator(),
        
        ColdBoot(),
        NoAudio(),
        ToggleA11y(),
        Paste()
    ]
    
    static var ios: [SubMenuItem] = [
        CopyName(),
        CopyUDID(),
        
        Separator(),
        
        Delete()
    ]
}
