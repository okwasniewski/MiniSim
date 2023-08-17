//
//  Menu.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import AppKit
import KeyboardShortcuts
import UserNotifications

class Menu: NSMenu {
    public let maxKeyEquivalent = 9
    
    var devices: [Device] = [] {
        didSet {
            populateDevices(isFirst: oldValue.isEmpty)
            assignKeyEquivalents()
        }
        willSet {
            let deviceNames = Set(devices.map({ $0.displayName }))
            let updatedDeviceNames = Set(newValue.map({ $0.displayName }))
            removeMenuItems(removedDevices: deviceNames.subtracting(updatedDeviceNames))
        }
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: "MiniSim")
        self.delegate = self
    }
    
    func getDevices() {
        if UserDefaults.standard.androidHome == nil {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var devicesArray: [Device] = []
                try devicesArray.append(contentsOf: DeviceService.getAndroidDevices())
                try devicesArray.append(contentsOf: DeviceService.getIOSDevices())
                self.devices = devicesArray
            } catch {
                NSAlert.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func getDeviceByName(name: String) -> Device? {
        return devices.first { $0.displayName == name }
    }
    
    private func removeMenuItems(removedDevices: Set<String>) {
        let itemsToRemove = self.items.filter({ removedDevices.contains($0.title) })
        itemsToRemove.forEach(safeRemoveItem)
    }
    
    @objc private func androidSubMenuClick(_ sender: NSMenuItem) {
        guard let tag = AndroidSubMenuItem(rawValue: sender.tag) else { return }
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else { return }
        
        DeviceService.handleAndroidAction(device: device, commandTag: tag, itemName: sender.title)
    }
    
    @objc private func IOSSubMenuClick(_ sender: NSMenuItem) {
        guard let tag = IOSSubMenuItem(rawValue: sender.tag) else { return }
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else { return }
        
        DeviceService.handleiOSAction(device: device, commandTag: tag, itemName: sender.title)
    }
    
    @objc private func deviceItemClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.title) else { return }
        guard let tag = DeviceMenuItem(rawValue: sender.tag) else { return }
        
        if device.booted {
            DeviceService.focusDevice(device)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                switch tag {
                case .launchAndroid:
                    try DeviceService.launchDevice(name: device.name)
                case .launchIOS:
                    try DeviceService.launchDevice(uuid: device.ID ?? "")
                }
            } catch {
                NSAlert.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func getKeyKequivalent(index: Int) -> String {
        return Character(UnicodeScalar(0x0030+index)!).lowercased()
    }
    
    private func assignKeyEquivalents() {
        let sections = MenuSections.allCases.map {$0.title}
        let deviceItems = items.filter { !sections.contains($0.title) }
        let iosDeviceNames = devices.filter({ $0.platform == Platform.ios }).map { $0.displayName }
        let androidDeviceNames = devices.filter({ $0.platform == Platform.android }).map { $0.displayName }
        
        let iosDevices = deviceItems.filter { iosDeviceNames.contains($0.title) }
        let androidDevices = deviceItems.filter { androidDeviceNames.contains($0.title) }
        
        assignKeyEquivalent(devices: iosDevices)
        assignKeyEquivalent(devices: androidDevices)
    }
    
    private func assignKeyEquivalent(devices: [NSMenuItem]) {
        for (index, item) in devices.enumerated() {
            if index > maxKeyEquivalent {
                DispatchQueue.main.async {
                    item.keyEquivalent = ""
                }
                continue
            }
            
            let keyEquivalent = getKeyKequivalent(index: index)
            
            if item.keyEquivalent == keyEquivalent {
                continue
            }
            
            DispatchQueue.main.async {
                if self.items.contains(item) {
                    item.keyEquivalent = keyEquivalent
                }
            }
        }
    }

    
    private func populateDevices(isFirst: Bool) {
        let sortedDevices = devices.sorted(by: { $0.platform == .android && $1.platform == .ios })
        for (index, device) in sortedDevices.enumerated() {
            let isAndroid = device.platform == .android
            if let itemIndex = items.firstIndex(where: { $0.title == device.displayName }) {
                DispatchQueue.main.async { [self] in
                    let item = self.items.get(at: itemIndex)
                    item?.state = device.booted ? .on : .off
                    item?.submenu = isAndroid ? populateAndroidSubMenu(booted: device.booted) : populateIOSSubMenu(booted: device.booted)
                }
                continue
            }
            
            let menuItem = NSMenuItem(
                title: device.displayName,
                action: #selector(deviceItemClick),
                keyEquivalent: "",
                type: isAndroid ? .launchAndroid : .launchIOS
            )
            
            menuItem.target = self
            menuItem.keyEquivalentModifierMask = isAndroid ? [.option] : [.command]
            menuItem.submenu = isAndroid ? populateAndroidSubMenu(booted: device.booted) : populateIOSSubMenu(booted: device.booted)
            menuItem.state = device.booted ? .on : .off
            
            DispatchQueue.main.async {
                let iosDevicesCount = self.devices.filter({ $0.platform == .ios }).count
                self.safeInsertItem(menuItem, at: isAndroid ? (isFirst ? index : iosDevicesCount) + 3 : 1)
            }
            
        }
    }
    
    private func populateAndroidSubMenu(booted: Bool) -> NSMenu {
        let subMenu = NSMenu()
        for item in AndroidSubMenuItem.allCases {
            if item == AndroidSubMenuItem.customCommand {
                continue
            }
            
            let menuItem = item.menuItem
            menuItem.target = self
            menuItem.action = #selector(androidSubMenuClick)
            if item.needBootedDevice && !booted {
                continue
            }
            if item.bootsDevice && booted {
                continue
            }
            subMenu.addItem(menuItem)
        }
        
        for item in DeviceService.getCustomCommands(platform: .android) {
            let menuItem = AndroidSubMenuItem.customCommand.menuItem
            menuItem.target = self
            menuItem.action = #selector(androidSubMenuClick)
            if item.needBootedDevice && !booted {
                continue
            }
            if item.bootsDevice ?? false && booted {
                continue
            }
            menuItem.image = NSImage(systemSymbolName: item.icon, accessibilityDescription: item.name)
            menuItem.title = item.name
            subMenu.addItem(menuItem)
        }
        return subMenu
    }
    
    private func populateIOSSubMenu(booted: Bool) -> NSMenu {
        let subMenu = NSMenu()
        for item in IOSSubMenuItem.allCases {
            if item == IOSSubMenuItem.customCommand {
                continue
            }
            let menuItem = item.menuItem
            menuItem.target = self
            menuItem.action = #selector(IOSSubMenuClick)
            subMenu.addItem(menuItem)
        }
        
        for item in DeviceService.getCustomCommands(platform: .ios) {
            let menuItem = IOSSubMenuItem.customCommand.menuItem
            menuItem.target = self
            menuItem.action = #selector(IOSSubMenuClick)
            if item.needBootedDevice && !booted {
                continue
            }
            if item.bootsDevice ?? false && booted {
                continue
            }
            menuItem.image = NSImage(systemSymbolName: item.icon, accessibilityDescription: item.name)
            menuItem.title = item.name
            subMenu.addItem(menuItem)
        }
        return subMenu
    }
    
    private func safeInsertItem(_ item: NSMenuItem, at index: Int) {
        guard !items.contains(where: {$0.title == item.title}), index <= items.count else {
            return
        }
        
        insertItem(item, at: index)
    }
    
    private func safeRemoveItem(_ item: NSMenuItem?) {
        guard let item = item,
              items.contains(item) else {
            return
        }
        
        removeItem(item)
    }
}

extension Menu: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        NotificationCenter.default.post(name: .menuWillOpen, object: nil)
        self.getDevices()
        KeyboardShortcuts.disable(.toggleMiniSim)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        NotificationCenter.default.post(name: .menuDidClose, object: nil)
        KeyboardShortcuts.enable(.toggleMiniSim)
    }
}
