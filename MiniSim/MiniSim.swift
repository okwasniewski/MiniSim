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
    private var menu: NSMenu!
    
    @objc let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private var devices: [Device] = []
    
    var deviceService: DeviceServiceProtocol
    
    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
        statusBar = NSStatusBar()
        menu = NSMenu()
        statusItem.menu = menu
        
        super.init()
        
        updateMenuBarIcon()
        populateSections()
        populateiOSDevices()
        populateAndroidDevices()
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
        if let tag = MenuItemType(rawValue: sender.tag) {
            switch tag {
            case .launchAndroid:
                if let device = getDeviceByName(name: sender.title) {
                    deviceService.launchDevice(name: device.name) { result in
                        if case .failure(let error) = result {
                            DispatchQueue.main.async {
                                NSAlert.showError(error: error)
                            }
                        }
                    }
                }
            case .launchIOS:
                if let device = getDeviceByName(name: sender.title) {
                    deviceService.launchDevice(uuid: device.uuid ?? "") { result in
                        if case .failure(let error) = result {
                            DispatchQueue.main.async {
                                NSAlert.showError(error: error)
                            }
                        }
                    }
                }
                
            case .preferences:
                settingsController.show()
            case .quit:
                NSApp.terminate(sender)
            }
            
        }
    }
    
    private func getDeviceByName(name: String) -> Device? {
        devices.first { $0.name == name }
    }
    
    private func updateMenuBarIcon() {
        if let button = statusItem.button {
            button.toolTip = "MiniSim"
            let itemImage = NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone")
            itemImage?.isTemplate = true
            button.image = itemImage
        }
    }
    
    private func populateSections() {
        menu.addItem(withTitle: "iOS Simulators", action: nil, keyEquivalent: "")
        
        menu.addItem(.separator())
        menu.addItem(withTitle: "Android emulators", action: nil, keyEquivalent: "")
        
        menu.addItem(.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(self.menuItemAction(_:)),
            keyEquivalent: "q",
            type: .quit,
            showImage: false
        )
        quitItem.target = self
        
        let preferences = NSMenuItem(
            title: "Preferences",
            action: #selector(self.menuItemAction(_:)),
            keyEquivalent: ",",
            type: .preferences,
            showImage: false
        )
        preferences.target = self
        menu.addItem(preferences)
        menu.addItem(quitItem)
    }
    
    private func populateAndroidDevices() {
        DispatchQueue.global(qos: .background).async { [self] in
            self.deviceService.getDevices(deviceType: .Android) { result in
                switch result {
                case .success(let devices):
                    Array(devices.enumerated()).forEach { index, device in
                        let menuItem = NSMenuItem(
                            title: device.name,
                            action: #selector(self.menuItemAction(_:)),
                            keyEquivalent: index <= 9 ? "\(index)" : "",
                            type: .launchAndroid
                        )
                        menuItem.target = self
                        menuItem.keyEquivalentModifierMask = [.option]
                        
                        DispatchQueue.main.async {
                            self.devices.append(device)
                            self.menu.insertItem(menuItem, at: index + 3)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        NSAlert.showError(error: error)
                    }
                }
            }
        }
    }
    
    private func populateiOSDevices() {
        DispatchQueue.global(qos: .background).async { [self] in
            deviceService.getDevices(deviceType: .iOS) { result in
                switch result {
                case .success(let devices):
                    Array(devices.enumerated()).forEach { index, device in
                        let menuItem = NSMenuItem(
                            title: device.name,
                            action: #selector(self.menuItemAction(_:)),
                            keyEquivalent: index <= 9 ? "\(index)" : "",
                            type: .launchIOS
                        )
                        menuItem.target = self
                        
                        DispatchQueue.main.async {
                            self.devices.append(device)
                            self.menu.insertItem(menuItem, at: index + 1)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        NSAlert.showError(error: error)
                    }
                }
            }
        }
    }
}
