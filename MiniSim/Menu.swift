//
//  Menu.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import AppKit
import KeyboardShortcuts

class Menu: NSMenu {
    var deviceService: DeviceServiceProtocol!
    var devices: [Device] = [] {
        didSet {
            buildMenu()
        }
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
        super.init(title: "MiniSim")
        self.delegate = self
    }
    
    private func getDeviceByName(name: String) -> Device? {
        devices.first { $0.name == name }
    }
    
    @objc private func deviceItemClick(_ sender: NSMenuItem) {
        if let tag = DeviceMenuItem(rawValue: sender.tag) {
            switch tag {
            case .launchAndroid:
                if let device = getDeviceByName(name: sender.title) {
                    deviceService.launchDevice(name: device.name, additionalArguments: []) { result in
                        if case .failure(let error) = result {
                            NSAlert.showError(message: error.localizedDescription)
                        }
                    }
                }
            case .launchIOS:
                if let device = getDeviceByName(name: sender.title) {
                    deviceService.launchDevice(uuid: device.uuid ?? "") { result in
                        if case .failure(let error) = result {
                            NSAlert.showError(message: error.localizedDescription)
                        }
                    }
                }
            case .coldBootAndroid:
                if let device = getDeviceByName(name: sender.parent?.title ?? "") {
                    deviceService.launchDevice(name: device.name, additionalArguments: ["-no-snapshot"]) { result in
                        if case .failure(let error) = result {
                            NSAlert.showError(message: error.localizedDescription)
                        }
                    }
                }
                
            case .toggleA11yAndroid:
                if let device = getDeviceByName(name: sender.parent?.title ?? "") {
                    deviceService.toggleA11y(device: device) { result in
                        if case .failure(let error) = result {
                            NSAlert.showError(message: error.localizedDescription)
                        }
                    }
                }
                
            case .androidNoAudio:
                if let device = getDeviceByName(name: sender.parent?.title ?? "") {
                    deviceService.launchDevice(name: device.name, additionalArguments: ["-no-audio"]) { result in
                        if case .failure(let error) = result {
                                NSAlert.showError(message: error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    private func getKeyKequivalent(index: Int) -> String {
        return Character(UnicodeScalar(0x0030+index)!).lowercased()
    }
    
    private func buildMenu() {
        if (self.items.count == devices.count) {
            return
        }
        
        let androidDevices = devices.filter({ $0.isAndroid })
        let iOSDevices = devices.filter({ !$0.isAndroid })
        
        Array(androidDevices.enumerated()).forEach { index, device in
            let menuItem = NSMenuItem(
                title: device.name,
                action: #selector(deviceItemClick),
                keyEquivalent: getKeyKequivalent(index: index),
                type: .launchAndroid
            )
            menuItem.target = self
            menuItem.keyEquivalentModifierMask = [.option]
            menuItem.submenu = populateAndroidSubMenu()
            
            if !items.contains(where: { $0.title == device.name }) {
                self.insertItem(menuItem, at: 3)
            }
        }
        
        Array(iOSDevices.enumerated()).forEach { index, device in
            let menuItem = NSMenuItem(
                title: device.name,
                action: #selector(deviceItemClick),
                keyEquivalent: getKeyKequivalent(index: index),
                type: device.isAndroid ? .launchAndroid : .launchIOS
            )
            menuItem.target = self
            menuItem.keyEquivalentModifierMask = [.command]
            
            if !items.contains(where: { $0.title == device.name }) {
                self.insertItem(menuItem, at: 1)
            }
        }
    }
    
    private func populateAndroidSubMenu() -> NSMenu {
        let subMenu = NSMenu()
        let coldBoot = NSMenuItem(
            title: "Cold boot",
            action: #selector(deviceItemClick),
            keyEquivalent: "",
            type: .coldBootAndroid,
            image: NSImage(systemSymbolName: "sunrise.fill", accessibilityDescription: "Cold boot")
        )
        
        let noAudio = NSMenuItem(
            title: "Run without audio",
            action: #selector(deviceItemClick),
            keyEquivalent: "",
            type: .androidNoAudio,
            image: NSImage(systemSymbolName: "speaker.slash.fill", accessibilityDescription: "No audio")
        )
        
        let toggleA11 = NSMenuItem(
            title: "Toggle accessibility",
            action: #selector(deviceItemClick),
            keyEquivalent: "",
            type: .toggleA11yAndroid,
            image: NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: "Toggle accessibility")
        )
        
        coldBoot.target = self
        noAudio.target = self
        toggleA11.target = self
        
        subMenu.addItem(coldBoot)
        subMenu.addItem(noAudio)
        subMenu.addItem(toggleA11)
        
        return subMenu
    }
}

extension Menu: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        KeyboardShortcuts.disable(.toggleMiniSim)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.toggleMiniSim)
    }
}
