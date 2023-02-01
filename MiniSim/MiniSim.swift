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
    
    private var devices: [Device] = []
    
    var deviceService: DeviceServiceProtocol
    
    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
        statusBar = NSStatusBar()
        menu = Menu()
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
                    deviceService.launchDevice(name: device.name, additionalArguments: []) { result in
                        if case .failure(let error) = result {
                            guard let shellOutError = error as? ShellOutError else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                NSAlert.showError(message: shellOutError.message)
                            }
                        }
                    }
                }
            case .launchIOS:
                if let device = getDeviceByName(name: sender.title) {
                    deviceService.launchDevice(uuid: device.uuid ?? "") { result in
                        if case .failure(let error) = result {
                            guard let shellOutError = error as? ShellOutError else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                NSAlert.showError(message: shellOutError.message)
                            }
                        }
                    }
                }
            case .coldBootAndroid:
                if let device = getDeviceByName(name: sender.parent?.title ?? "") {
                    deviceService.launchDevice(name: device.name, additionalArguments: ["-no-snapshot"]) { result in
                        if case .failure(let error) = result {
                            DispatchQueue.main.async {
                                guard let shellOutError = error as? ShellOutError else {
                                    return
                                }
                                NSAlert.showError(message: shellOutError.message)
                            }
                        }
                    }
                }
                
            case .toggleA11yAndroid:
                if let device = getDeviceByName(name: sender.parent?.title ?? "") {
                    deviceService.toggleA11y(device: device)
                }
                
            case .androidNoAudio:
                if let device = getDeviceByName(name: sender.parent?.title ?? "") {
                    deviceService.launchDevice(name: device.name, additionalArguments: ["-no-audio"]) { result in
                        if case .failure(let error) = result {
                            DispatchQueue.main.async {
                                guard let shellOutError = error as? ShellOutError else {
                                    return
                                }
                                NSAlert.showError(message: shellOutError.message)
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
            image: NSImage()
        )
        quitItem.target = self
        
        let preferences = NSMenuItem(
            title: "Preferences",
            action: #selector(self.menuItemAction(_:)),
            keyEquivalent: ",",
            type: .preferences,
            image: NSImage()
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
                        
                        menuItem.submenu = self.populateAndroidSubMenu()
                        
                        DispatchQueue.main.async {
                            self.devices.append(device)
                            self.menu.insertItem(menuItem, at: index + 3)
                        }
                    }
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
    
    private func populateAndroidSubMenu() -> NSMenu {
        let subMenu = NSMenu()
        let coldBoot = NSMenuItem(
            title: "Cold boot",
            action: #selector(self.menuItemAction(_:)),
            keyEquivalent: "",
            type: .coldBootAndroid,
            image: NSImage(systemSymbolName: "sunrise.fill", accessibilityDescription: "Cold boot")
        )
        coldBoot.target = self
        
        let noAudio = NSMenuItem(
            title: "Run without audio",
            action: #selector(self.menuItemAction(_:)),
            keyEquivalent: "",
            type: .androidNoAudio,
            image: NSImage(systemSymbolName: "speaker.slash.fill", accessibilityDescription: "No audio")
        )
        
        let toggleA11 = NSMenuItem(
            title: "Toggle accessibility",
            action: #selector(self.menuItemAction(_:)),
            keyEquivalent: "",
            type: .toggleA11yAndroid,
            image: NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: "No audio")
        )
        
        coldBoot.target = self
        noAudio.target = self
        toggleA11.target = self
        
        subMenu.addItem(coldBoot)
        subMenu.addItem(noAudio)
        subMenu.addItem(.separator())
        subMenu.addItem(toggleA11)
        
        return subMenu
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
                        guard let shellOutError = error as? ShellOutError else {
                            return
                        }
                        NSAlert.showError(message: shellOutError.message)
                    }
                }
            }
        }
    }
}
