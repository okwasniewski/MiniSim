//
//  StatusBarController.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit
import Preferences
import SwiftUI


class MiniSim: NSObject {
    private var statusBar: NSStatusBar!
    private var menu: Menu!
    
    @objc let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override init() {
        statusBar = NSStatusBar()
        menu = Menu()
        statusItem.menu = menu
        
        super.init()
        
        if let button = statusItem.button {
            button.toolTip = "MiniSim"
            let itemImage = NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone")
            button.image = itemImage
        }
        
        settingsController.window?.delegate = self
        
        populateSections()
        self.menu.getDevices()
    }
    
    private lazy var settingsController = SettingsWindowController(
        panes: [
            Settings.Pane(
                identifier: .preferences,
                title: "Preferences",
                toolbarIcon: NSImage(systemSymbolName: "gear", accessibilityDescription: "") ?? NSImage()
            ) {
                Preferences()
            },
            Settings.Pane(
                identifier: .devices,
                title: "Devices",
                toolbarIcon: NSImage(systemSymbolName: "iphone", accessibilityDescription: "") ?? NSImage()
            ) {
                Devices()
            },
            Settings.Pane(
                identifier: .about,
                title: "About",
                toolbarIcon: NSImage(systemSymbolName: "info.circle", accessibilityDescription: "") ?? NSImage()
            ) {
                About()
            }
        ],
        style: .toolbarItems,
        animated: false
    )
    
    func open() {
        self.statusItem.button?.performClick(self)
    }
    
    @objc func menuItemAction(_ sender: NSMenuItem) {
        if let tag = MenuSections(rawValue: sender.tag) {
            switch tag {
            case .preferences:
                settingsController.show()
            case .quit:
                NSApp.terminate(sender)
            default:
                break
            }
            
        }
    }
    
    private func populateSections() {
        MenuSections.allCases.map({$0.menuItem}).forEach { item in
            if item.tag >= MenuSections.preferences.rawValue {
                item.action = #selector(menuItemAction)
                item.target = self
            } else {
                item.isEnabled = false
            }
            menu.addItem(item)
        }
    }
}


extension MiniSim: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
