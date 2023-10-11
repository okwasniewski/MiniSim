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
            populateDevices()
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
        let userDefaults = UserDefaults.standard
        DeviceService.getAllDevices(
            android: userDefaults.enableAndroidEmulators && userDefaults.androidHome != nil,
            iOS: userDefaults.enableiOSSimulators
        ) { devices, error in
            if let error {
                NSAlert.showError(message: error.localizedDescription)
                return
            }
            self.devices = devices
        }
    }
    
    private func getDeviceByName(name: String) -> Device? {
        return devices.first { $0.displayName == name }
    }
    
    private func removeMenuItems(removedDevices: Set<String>) {
        self.items.filter({ removedDevices.contains($0.title) })
            .forEach(safeRemoveItem)
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
        
        if device.booted {
            DeviceService.focusDevice(device)
            return
        }
        
        DeviceService.launch(device: device) { error in
            if let error {
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
                item.keyEquivalent = ""
                continue
            }
            
            let keyEquivalent = getKeyKequivalent(index: index)
            
            if item.keyEquivalent == keyEquivalent {
                continue
            }
            
            if self.items.contains(item) {
                item.keyEquivalent = keyEquivalent
            }
        }
    }
    
    // MARK: Populate sections
    private func populateDevices() {
        let sortedDevices = devices.sorted(by: { $0.platform == .android && $1.platform == .ios })
        let platformSections: [MenuSections] = [.iOSHeader, .androidHeader]
        for section in platformSections {
            let devices = filter(devices: sortedDevices, for: section)
            let menuItems = devices.map { createMenuItem(for: $0) }
            self.updateSection(with: Array(menuItems), section: section)
        }
    }
    
    private func filter(devices: [Device], for section: MenuSections) -> [Device] {
        let platform: Platform = section == .iOSHeader ? .ios : .android
        return devices.filter { $0.platform == platform }
    }
    
    private func updateSection(with items: [NSMenuItem], section: MenuSections) {
        guard let header = self.items.first(where: { $0.tag == section.rawValue }),
              let startIndex = self.items.firstIndex(of: header) else {
            return
        }
        
        var count = 0
        items.forEach { menuItem in
            count += 1
            if let itemIndex = self.items.firstIndex(where: { $0.title == menuItem.title }) {
                self.replaceMenuItem(at: itemIndex, with: menuItem)
                return
            }
            self.safeInsertItem(menuItem, at: startIndex + count)
        }
    }

    private func createMenuItem(for device: Device) -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: device.displayName,
            action: #selector(deviceItemClick),
            keyEquivalent: "",
            type: device.platform == .ios ? .launchIOS : .launchAndroid
        )
        
        menuItem.target = self
        menuItem.keyEquivalentModifierMask = [.command]
        menuItem.submenu = buildSubMenu(for: device)
        menuItem.state = device.booted ? .on : .off
        return menuItem
    }
    
    private func replaceMenuItem(at index: Int, with newItem: NSMenuItem) {
        self.removeItem(at: index)
        self.insertItem(newItem, at: index)
    }
    
    func buildSubMenu(for device: Device) -> NSMenu {
        let subMenu = NSMenu()
        let platform = device.platform
        let callback = platform == .android ? #selector(androidSubMenuClick) : #selector(IOSSubMenuClick)
        let actionsSubMenu = createActionsSubMenu(
            for: platform.subMenuItems,
            isDeviceBooted: device.booted,
            callback: callback)
        let customCommandSubMenu = createCustomCommandsMenu(
            for: platform,
            isDeviceBooted: device.booted,
            callback: callback)
        (actionsSubMenu + customCommandSubMenu).forEach { subMenu.addItem($0) }
        return subMenu
    }

    func createActionsSubMenu(
        for subMenuItems: [SubMenuItem],
        isDeviceBooted: Bool,
        callback: Selector
    ) -> [NSMenuItem] {
        subMenuItems.filter { item in
            if item.needBootedDevice && !isDeviceBooted {
                return false
            }
            
            if item.bootsDevice && isDeviceBooted {
                return false
            }
            
            return true
        }.map { item in
            if item.isSeparator {
                return NSMenuItem.separator()
            }
            return NSMenuItem(menuItem: item, target: self, action: callback)
        }
    }
    
    func createCustomCommandsMenu(for platform: Platform, isDeviceBooted: Bool, callback: Selector) -> [NSMenuItem] {
        DeviceService.getCustomCommands(platform: platform)
            .filter {  item in
                if item.needBootedDevice && !isDeviceBooted {
                    return false
                }
                if item.bootsDevice ?? false && isDeviceBooted {
                    return false
                }
                return true
            }
            .map { NSMenuItem(command: $0, target: self, action: callback) }
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

extension Platform {
    var subMenuItems: [SubMenuItem] {
        switch self {
        case .android:
            return [
                AndroidSubMenuItem.copyName,
                AndroidSubMenuItem.copyAdbId,
                AndroidSubMenuItem.separator,
                AndroidSubMenuItem.coldBootAndroid,
                AndroidSubMenuItem.androidNoAudio,
                AndroidSubMenuItem.toggleA11yAndroid,
                AndroidSubMenuItem.pasteToEmulator
            ]
        case .ios:
            return [
                IOSSubMenuItem.copyName,
                IOSSubMenuItem.copyUDID,
                IOSSubMenuItem.separator,
                IOSSubMenuItem.deleteSim
            ]
        }
    }
}
