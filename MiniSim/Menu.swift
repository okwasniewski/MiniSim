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
    var iosDevices: [Device] = [] {
        didSet { populateIOSDevices() }
    }
    var androidDevices: [Device] = [] {
        didSet { populateAndroidDevices() }
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
        var device: Device?
        
        device = iosDevices.first { $0.name == name }
        
        if device == nil {
            device = androidDevices.first { $0.name == name }
        }
        return device
    }
    
    @objc private func androidSubMenuClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else {
            return
        }
        if let tag = AndroidSubMenuItem(rawValue: sender.tag) {
            switch tag {
            case .coldBootAndroid:
                deviceService.launchDevice(name: device.name, additionalArguments: ["-no-snapshot"]) { result in
                    if case .failure(let error) = result {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
                
            case .toggleA11yAndroid:
                deviceService.toggleA11y(device: device) { result in
                    if case .failure(let error) = result {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
                
            case .androidNoAudio:
                deviceService.launchDevice(name: device.name, additionalArguments: ["-no-audio"]) { result in
                    if case .failure(let error) = result {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
                
            case .copyAdbId:
                deviceService.copyAdbId(device: device) { result in
                    if case .failure(let error) = result {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
            case .copyName:
                NSPasteboard.general.copyToPasteboard(text: device.name)
            default:
                break
            }
        }
    }
    
    @objc private func IOSSubMenuClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else {
            return
        }
        if let tag = IOSSubMenuItem(rawValue: sender.tag) {
            switch tag {
            case .copyName:
                NSPasteboard.general.copyToPasteboard(text: device.name)
            case .copyUDID:
                NSPasteboard.general.copyToPasteboard(text: device.uuid ?? "")
            }
        }
    }
    
    @objc private func deviceItemClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.title) else {
            return
        }
        if let tag = DeviceMenuItem(rawValue: sender.tag) {
            switch tag {
            case .launchAndroid:
                deviceService.launchDevice(name: device.name, additionalArguments: []) { result in
                    if case .failure(let error) = result {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
            case .launchIOS:
                deviceService.launchDevice(uuid: device.uuid ?? "") { result in
                    if case .failure(let error) = result {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func getKeyKequivalent(index: Int) -> String {
        return Character(UnicodeScalar(0x0030+index)!).lowercased()
    }
    
    private func populateAndroidDevices() {
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
                DispatchQueue.main.async {
                    self.insertItem(menuItem, at: self.iosDevices.count + 3)
                }
            }
        }
    }
    
    private func populateIOSDevices() {
        Array(iosDevices.enumerated()).forEach { index, device in
            let menuItem = NSMenuItem(
                title: device.name,
                action: #selector(deviceItemClick),
                keyEquivalent: getKeyKequivalent(index: index),
                type: device.isAndroid ? .launchAndroid : .launchIOS
            )
            menuItem.target = self
            menuItem.keyEquivalentModifierMask = [.command]
            menuItem.submenu = populateIOSSubMenu()
            
            if !items.contains(where: { $0.title == device.name }) {
                DispatchQueue.main.async {
                    self.insertItem(menuItem, at: 1)
                }
            }
        }
    }
    
    private func populateAndroidSubMenu() -> NSMenu {
        let subMenu = NSMenu()
        AndroidSubMenuItem.allCases.map({$0.menuItem}).forEach { item in
            item.target = self
            item.action = #selector(androidSubMenuClick)
            subMenu.addItem(item)
        }
        return subMenu
    }
    
    private func populateIOSSubMenu() -> NSMenu {
        let subMenu = NSMenu()
        IOSSubMenuItem.allCases.map({$0.menuItem}).forEach { item in
            item.target = self
            item.action = #selector(IOSSubMenuClick)
            subMenu.addItem(item)
        }
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
