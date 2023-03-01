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
        willSet {
            removeMenuItems(removedDevices: Set(iosDevices).subtracting(Set(newValue)))
        }
    }
    
    var androidDevices: [Device] = [] {
        didSet { populateAndroidDevices() }
        willSet {
            removeMenuItems(removedDevices: Set(androidDevices).subtracting(Set(newValue)))
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
    
    func getDevices() {
        Task {
            do {
                self.androidDevices = try deviceService.getAndroidDevices()
                self.iosDevices = try deviceService.getIOSDevices()
            } catch {
                await NSAlert.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func getDeviceByName(name: String) -> Device? {
        var device: Device?
        
        device = iosDevices.first { $0.name == name }
        
        if device == nil {
            device = androidDevices.first { $0.name == name }
        }
        return device
    }
    
    private func removeMenuItems(removedDevices: Set<Device>) {
        for removedDevice in removedDevices {
            if let index = self.items.firstIndex(where: {$0.title == removedDevice.name}) {
                self.items.remove(at: index)
            }
        }
    }
    
    @objc private func androidSubMenuClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else { return }
        guard let tag = AndroidSubMenuItem(rawValue: sender.tag) else { return }
        
        Task {
            do {
                switch tag {
                case .coldBootAndroid:
                    try deviceService.launchDevice(name: device.name, additionalArguments:["-no-snapshot"])
                    
                case .androidNoAudio:
                    try deviceService.launchDevice(name: device.name, additionalArguments:["-no-audio"])
                    
                case .toggleA11yAndroid:
                    try deviceService.toggleA11y(device: device)
                    
                case .copyAdbId:
                    let deviceId = try deviceService.getAdbId(device: device)
                    NSPasteboard.general.copyToPasteboard(text: deviceId)
                    
                case .copyName:
                    NSPasteboard.general.copyToPasteboard(text: device.name)
                    
                case .pasteToEmulator:
                    let pasteboard = NSPasteboard.general
                    guard let clipboard = pasteboard.pasteboardItems?.first?.string(forType: .string) else { break }
                    try deviceService.sendText(device: device, text: clipboard)
                    
                default:
                    break
                }
            }
            catch {
                await NSAlert.showError(message: error.localizedDescription)
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
        guard let device = getDeviceByName(name: sender.title) else { return }
        guard let tag = DeviceMenuItem(rawValue: sender.tag) else { return }
        
        Task {
            do {
                switch tag {
                case .launchAndroid:
                    try deviceService.launchDevice(name: device.name, additionalArguments: [])
                case .launchIOS:
                    try deviceService.launchDevice(uuid: device.uuid ?? "")
                }
            } catch {
                await NSAlert.showError(message: error.localizedDescription)
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
        self.getDevices()
        KeyboardShortcuts.disable(.toggleMiniSim)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.toggleMiniSim)
    }
}
