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
            populateDevicesMenu(devices)
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
    
    func populateDefaultMenu() {
        var sections: [DeviceListSection] = []
        if UserDefaults.standard.enableiOSSimulators {
            sections.append(.iOS)
        }
        
        if UserDefaults.standard.enableAndroidEmulators {
            sections.append(.android)
        }
    
        if sections.isEmpty {
            return
        }
        
        var menuItems: [NSMenuItem] = []
        
        sections.forEach { section in
            var menuItem: NSMenuItem
            if #available(macOS 14.0, *) {
                menuItem = NSMenuItem.sectionHeader(title: "")
            } else {
                menuItem = NSMenuItem()
            }
            menuItem.tag = section.rawValue
            menuItem.title = section.title
            menuItem.toolTip = section.title
            
            menuItems.append(menuItem)
            menuItems.append(NSMenuItem.separator())
        }
        self.items = menuItems
    }

    func updateDevicesList() {
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
        self.items
            .filter({ removedDevices.contains($0.title) })
            .forEach(safeRemoveItem)
    }
    
    @objc private func androidSubMenuClick(_ sender: NSMenuItem) {
        guard let tag = SubMenuItems.Tags(rawValue: sender.tag) else { return }
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else { return }
        
        DeviceService.handleAndroidAction(device: device, commandTag: tag, itemName: sender.title)
    }
    
    @objc private func IOSSubMenuClick(_ sender: NSMenuItem) {
        guard let tag = SubMenuItems.Tags(rawValue: sender.tag) else { return }
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
        let sections = DeviceListSection.allCases.map {$0.title}
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
    private func populateDevicesMenu(_ devices: [Device]) {
        let platformSections: [DeviceListSection] = sections
        for section in platformSections {
            let sectionDevices = filter(devices: devices, for: section)
                .sorted(by: { $0.name < $1.name })
            let menuItems = sectionDevices.map { createMenuItem(for: $0) }
            self.updateSection(with: menuItems, section: section)
        }
    }
    
    var sections: [DeviceListSection] {
        var sections: [DeviceListSection] = []
        if UserDefaults.standard.enableAndroidEmulators {
            sections.append(.android)
        }
        if UserDefaults.standard.enableiOSSimulators {
            sections.append(.iOS)
        }
        return sections
    }
    
    private func filter(devices: [Device], for section: DeviceListSection) -> [Device] {
        let platform: Platform = section == .iOS ? .ios : .android
        return devices.filter { $0.platform == platform }
    }
    
    private func updateSection(with items: [NSMenuItem], section: DeviceListSection) {
        guard let header = self.items.first(where: { $0.tag == section.rawValue }),
              let startIndex = self.items.firstIndex(of: header) else {
            return
        }
        
        for menuItem in items.reversed() {
            if let itemIndex = self.items.firstIndex(where: { $0.title == menuItem.title }) {
                self.replaceMenuItem(at: itemIndex, with: menuItem)
                continue
            }
            self.safeInsertItem(menuItem, at: startIndex + 1)
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
        menuItem.keyEquivalentModifierMask = device.platform == .android ? [.option] : [.command]
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
        subMenuItems.compactMap { item in
            if item is SubMenuItems.Separator {
                return NSMenuItem.separator()
            }
             
            if let item = item as? SubMenuActionItem {
                if item.needBootedDevice && !isDeviceBooted {
                    return nil
                }
                
                if item.bootsDevice && isDeviceBooted {
                    return nil
                }
                
                return NSMenuItem(menuItem: item, target: self, action: callback)
            }
            
            return nil
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
        self.updateDevicesList()
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
            return SubMenuItems.android
        case .ios:
            return SubMenuItems.ios
        }
    }
}
