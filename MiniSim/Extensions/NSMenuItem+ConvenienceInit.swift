//
//  NSMenuItem+ConvenienceInit.swift
//  MiniSim
//
//  Created by Anton Kolchunov on 11.10.23.
//

import Cocoa
import Foundation

extension NSMenuItem {
    convenience init(target: AnyObject, action: Selector) {
        self.init()
        self.target = target
        self.action = action
    }
    
    convenience init(
        menuItem: SubMenuItem,
        target: AnyObject,
        action: Selector
    ) {
        self.init(target: target, action: action)
        self.tag = menuItem.tag
        self.image = menuItem.image
        self.title = menuItem.title
        self.toolTip = menuItem.title
        self.target = target
        self.action = action
    }
    
    convenience init(
        command: Command,
        target: AnyObject,
        action: Selector
    ) {
        self.init(target: target, action: action)
        self.image = NSImage(
            systemSymbolName: command.icon,
            accessibilityDescription: command.name
        )
        self.title = command.name
    }
    
    convenience init(mainMenuItem: MainMenuActions, target: AnyObject, action: Selector) {
        self.init(target: target, action: action)
        self.tag = mainMenuItem.rawValue
        self.keyEquivalent = mainMenuItem.keyEquivalent
        self.title = mainMenuItem.title
        self.toolTip = mainMenuItem.title
    }
}
