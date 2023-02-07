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
                DispatchQueue.main.async {
                    self.insertItem(menuItem, at: iOSDevices.count + 3)
                }
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
}

extension Menu: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        KeyboardShortcuts.disable(.toggleMiniSim)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.toggleMiniSim)
    }
}
