//
//  StatusBarController.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit
import Preferences
import SwiftUI
import ShellOut


class MiniSim: NSObject {
    private var statusBar: NSStatusBar!
    private var menu: Menu!
    
    @objc let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    
    var deviceService: DeviceServiceProtocol
    
    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
        statusBar = NSStatusBar()
        menu = Menu(deviceService: deviceService)
        statusItem.menu = menu
        
        super.init()
        
        if let button = statusItem.button {
            button.toolTip = "MiniSim"
            let itemImage = NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone")
            button.image = itemImage
        }
        
        populateSections {
            getAndroidDevices()
            getiOSDevices()
        }
    }
    
    private lazy var settingsController = PreferencesWindowController(
        panes: [
            Settings.Pane(
                identifier: .preferences,
                title: "Preferences",
                toolbarIcon: NSImage(systemSymbolName: "gear", accessibilityDescription: "") ?? NSImage()
            ) {
                Preferences()
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
        animated: false,
        hidesToolbarForSingleItem: true
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
    
    private func populateSections(_ completion: () -> Void) {
        MenuSections.allCases.map({$0.menuItem}).forEach { item in
            item.target = self
            if item.tag >= MenuSections.preferences.rawValue {
                item.action = #selector(menuItemAction)
            }
            menu.addItem(item)
        }
        completion()
    }
    
    private func getAndroidDevices() {
        self.deviceService.getAndroidDevices { result in
            switch result {
            case .success(let devices):
                self.menu.devices.append(contentsOf: devices)
            case .failure(let error):
                DispatchQueue.main.async {
                    guard let shellOutError = error as? ShellOutError else {
                        return
                    }
                    NSAlert.showError(message: shellOutError.message)
                }
            }
        }
    }
    
    private func getiOSDevices() {
        deviceService.getIOSDevices { result in
            switch result {
            case .success(let devices):
                self.menu.devices.append(contentsOf: devices)
            case .failure(let error):
                DispatchQueue.main.async {
                    guard let shellOutError = error as? ShellOutError else {
                        return
                    }
                    NSAlert.showError(message: shellOutError.message)
                }
            }
        }
    }
}
