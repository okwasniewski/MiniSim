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
    
    var deviceService: DeviceServiceProtocol!
    var devices: [Device] = [] {
        didSet {
            populateDevices(isFirst: oldValue.isEmpty)
            assignKeyEquivalents()
        }
        willSet {
            let deviceNames = Set(devices.map({ $0.name }))
            let updatedDeviceNames = Set(newValue.map({ $0.name }))
            removeMenuItems(removedDevices: deviceNames.subtracting(updatedDeviceNames))
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
                var devicesArray: [Device] = []
                try devicesArray.append(contentsOf: deviceService.getAndroidDevices())
                try devicesArray.append(contentsOf: deviceService.getIOSDevices())
                devices = devicesArray
            } catch {
                await NSAlert.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func getDeviceByName(name: String) -> Device? {
        return devices.first { $0.name == name }
    }
    
    private func removeMenuItems(removedDevices: Set<String>) {
        let itemsToRemove = self.items.filter({ removedDevices.contains($0.title) })
        itemsToRemove.forEach(safeRemoveItem)
    }
    
    private func getAdditionalLaunchParams() -> [Parameter]? {
        guard let paramData = UserDefaults.standard.parameters else { return nil }
        if let decodedData = try? JSONDecoder().decode([Parameter].self, from: paramData) {
            return decodedData
        }
        return nil
    }
    
    @objc private func androidSubMenuClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.parent?.title ?? "") else { return }
        guard let tag = AndroidSubMenuItem(rawValue: sender.tag) else { return }
        
        Task {
            do {
                switch tag {
                case .coldBootAndroid:
                    var params = ["-no-snapshot"]
                    if let additionalParams = getAdditionalLaunchParams() {
                        params.append(contentsOf: additionalParams.filter({$0.enabled}).map({$0.command}))
                    }
                    try deviceService.launchDevice(name: device.name, additionalArguments:params)
                    
                case .androidNoAudio:
                    var params = ["-no-audio"]
                    if let additionalParams = getAdditionalLaunchParams() {
                        params.append(contentsOf: additionalParams.filter({$0.enabled}).map({$0.command}))
                    }
                    try deviceService.launchDevice(name: device.name, additionalArguments:params)
                    
                case .toggleA11yAndroid:
                    try deviceService.toggleA11y(device: device)
                    
                case .copyAdbId:
                    if let deviceId = device.ID {
                        NSPasteboard.general.copyToPasteboard(text: deviceId)
                        showNotification(title: "Device ID copied to clipboard!", body: deviceId)
                    }
                    
                case .copyName:
                    NSPasteboard.general.copyToPasteboard(text: device.name)
                    showNotification(title: "Device name copied to clipboard!", body: device.name)
                    
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
                showNotification(title: "Device name copied to clipboard!", body: device.name)
            case .copyUDID:
                if let deviceID = device.ID {
                    NSPasteboard.general.copyToPasteboard(text: deviceID)
                    showNotification(title: "Device ID copied to clipboard!", body: deviceID)
                }
            }
        }
    }
    
    @objc private func deviceItemClick(_ sender: NSMenuItem) {
        guard let device = getDeviceByName(name: sender.title) else { return }
        guard let tag = DeviceMenuItem(rawValue: sender.tag) else { return }
        
        if device.booted {
            Task {
                deviceService.focusDevice(device)
            }
            return
        }
        
        Task {
            do {
                switch tag {
                case .launchAndroid:
                    var params: [String] = []
                    if let additionalParams = getAdditionalLaunchParams() {
                        params.append(contentsOf: additionalParams.filter({$0.enabled}).map({$0.command}))
                    }
                    try deviceService.launchDevice(name: device.name, additionalArguments: params)
                case .launchIOS:
                    try deviceService.launchDevice(uuid: device.ID ?? "")
                }
            } catch {
                await NSAlert.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func getKeyKequivalent(index: Int) -> String {
        return Character(UnicodeScalar(0x0030+index)!).lowercased()
    }
    
    private func assignKeyEquivalents() {
        let sections = MenuSections.allCases.map {$0.title}
        let deviceItems = items.filter { !sections.contains($0.title) }
        let iosDeviceNames = devices.filter({ !$0.isAndroid }).map { $0.name }
        let androidDeviceNames = devices.filter({ $0.isAndroid }).map { $0.name }

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
                item.keyEquivalent = keyEquivalent
            }
        }
    }
    
    private func populateDevices(isFirst: Bool) {
        let sortedDevices = devices.sorted(by: { $0.isAndroid && !$1.isAndroid })
        for (index, device) in sortedDevices.enumerated() {
            if let itemIndex = items.firstIndex(where: { $0.title == device.name }) {
                DispatchQueue.main.async {
                    let item = self.items.get(at: itemIndex)
                    item?.state = device.booted ? .on : .off
                    if device.isAndroid {
                        item?.submenu = self.populateAndroidSubMenu(booted: device.booted)
                    }
                }
                continue
            }
            
            let menuItem = NSMenuItem(
                title: device.name,
                action: #selector(deviceItemClick),
                keyEquivalent: "",
                type: device.isAndroid ? .launchAndroid : .launchIOS
            )
            
            menuItem.target = self
            menuItem.keyEquivalentModifierMask = device.isAndroid ? [.option] : [.command]
            menuItem.submenu = device.isAndroid ? populateAndroidSubMenu(booted: device.booted) : populateIOSSubMenu()
            menuItem.state = device.booted ? .on : .off
            
            DispatchQueue.main.async {
                let iosDevicesCount = self.devices.filter({ !$0.isAndroid }).count
                self.safeInsertItem(menuItem, at: device.isAndroid ? (isFirst ? index : iosDevicesCount) + 3 : 1)
            }
            
        }
    }
    
    private func populateAndroidSubMenu(booted: Bool) -> NSMenu {
        let subMenu = NSMenu()
        for item in AndroidSubMenuItem.allCases {
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
    
    private func showNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
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
        self.getDevices()
        KeyboardShortcuts.disable(.toggleMiniSim)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.toggleMiniSim)
    }
}
