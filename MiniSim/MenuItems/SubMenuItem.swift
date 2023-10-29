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
        let title: String = NSLocalizedString("Copy name", comment: "")
        let tag: Int = Tags.copyName.rawValue
        let bootsDevice: Bool = false
        let needBootedDevice: Bool = false
        let image = NSImage(
            systemSymbolName: "square.and.arrow.up",
            accessibilityDescription: "Copy name"
        )
    }
    
    struct CopyID: SubMenuActionItem {
        let title: String = NSLocalizedString("Copy ID", comment: "")
        let tag: Int = Tags.copyID.rawValue
        let bootsDevice: Bool = false
        let needBootedDevice: Bool = true
        let image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: "Copy ID"
        )
    }
    
    struct CopyUDID: SubMenuActionItem {
        let title: String = NSLocalizedString("Copy UDID", comment: "")
        let tag: Int = Tags.copyID.rawValue
        let bootsDevice: Bool = false
        let needBootedDevice: Bool = false
        let image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: "Copy UDID"
        )
    }
    
    struct ColdBoot: SubMenuActionItem {
        let title: String = NSLocalizedString("Cold boot", comment: "")
        let tag: Int = Tags.coldBoot.rawValue
        let bootsDevice: Bool = true
        let needBootedDevice: Bool = false
        let image = NSImage(
            systemSymbolName: "sunrise.fill",
            accessibilityDescription: "Cold boot"
        )
    }
    
    struct NoAudio: SubMenuActionItem {
        let title: String = NSLocalizedString("Run without audio", comment: "")
        let tag: Int = Tags.noAudio.rawValue
        let bootsDevice: Bool = true
        let needBootedDevice: Bool = false
        let image = NSImage(
            systemSymbolName: "speaker.slash.fill",
            accessibilityDescription: "Run without audio"
        )
    }
    
    struct ToggleA11y: SubMenuActionItem {
        let title: String = NSLocalizedString("Toggle accessibility", comment: "")
        let tag: Int = Tags.toggleA11y.rawValue
        let bootsDevice: Bool = false
        let needBootedDevice: Bool = true
        let image = NSImage(
            systemSymbolName: "figure.walk.circle.fill",
            accessibilityDescription: "Toggle accessibility"
        )
    }
    
    struct Paste: SubMenuActionItem {
        let title: String = NSLocalizedString("Paste clipboard to device", comment: "")
        let tag: Int = Tags.paste.rawValue
        let bootsDevice: Bool = false
        let needBootedDevice: Bool = true
        let image = NSImage(
            systemSymbolName: "keyboard",
            accessibilityDescription: "Keyboard"
        )
    }
    
    struct Delete: SubMenuActionItem {
        let title: String = NSLocalizedString("Delete simulator", comment: "")
        let tag: Int = Tags.paste.rawValue
        let bootsDevice: Bool = false
        let needBootedDevice: Bool = false
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
