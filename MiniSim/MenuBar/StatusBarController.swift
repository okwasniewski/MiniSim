//
//  StatusBarController.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit

class StatusBarController {
    private var statusBar: NSStatusBar
    private var menu: NSMenu
    private(set) var statusItem: NSStatusItem
    
    private var devices: [Device] = []
    
    var deviceService: DeviceServiceProtocol
    
    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
        
        statusBar = NSStatusBar()
        menu = NSMenu()
        menu.autoenablesItems = true
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
        
        if let button = statusItem.button {
            button.toolTip = "MiniSim"
            button.image = NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone")
        }
        
        setupSections()
        
        self.getDevices()
    }
    
    @objc func handleDeviceTap(_ sender: NSMenuItem) {
        let device = devices.first { $0.name == sender.title }
        
        guard let device else {
            return
        }
        
        if device.isAndroid {
            deviceService.launchDevice(name: device.name)
            return
        }
        
        if let uuid = device.uuid {
            deviceService.launchDevice(uuid: uuid)
        }
    }
    
    @objc func quitApp(_ sender: NSMenuItem) {
        if sender.title == "Quit" {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func setupSections() {
        menu.addItem(withTitle: "iOS Simulators", action: nil, keyEquivalent: "")
        
        menu.addItem(.separator())
        menu.addItem(withTitle: "Android emulators", action: nil, keyEquivalent: "")
        
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q").target = self
    }
    
    
    private func getDevices() {
        
        DispatchQueue.global(qos: .background).async { [self] in
            self.deviceService.getDevices(deviceType: .Android) { result in
                switch result {
                case .success(let devices):
                    Array(devices.enumerated()).forEach { index, device in
                        
                        let menuItem = NSMenuItem(
                            title: device.name,
                            action: #selector(self.handleDeviceTap),
                            keyEquivalent: "\(index)",
                            systemSymbolName: self.getSystemImageFromName(name: device.name)
                        )
                        menuItem.keyEquivalentModifierMask = [.option]
                        if (index > 9) {
                            menuItem.keyEquivalentModifierMask = [.option, .control]
                        }
                        menuItem.target = self
                        
                        self.devices.append(device)
                        self.menu.insertItem(menuItem, at: 3)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
            deviceService.getDevices(deviceType: .iOS) { result in
                switch result {
                case .success(let devices):
                    Array(devices.enumerated()).forEach { index, device in
                        let menuItem = NSMenuItem(
                            title: device.name,
                            action: #selector(self.handleDeviceTap),
                            keyEquivalent: "\(index)",
                            systemSymbolName: self.getSystemImageFromName(name: device.name)
                        )
                        
                        if (index > 9) {
                            menuItem.keyEquivalentModifierMask = [.command, .option]
                        }
                        
                        menuItem.target = self
                        
                        self.devices.append(device)
                        self.menu.insertItem(menuItem, at: 1)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    private func getSystemImageFromName(name: String) -> String {
        if name.contains("Apple TV") {
            return "appletv.fill"
        }
        
        if (name.contains("iPad") || name.contains("Tablet")) {
            return "ipad.gen2.landscape"
        }
        
        if name.contains("TV") {
            return "tv"
        }
        
        return "iphone.gen2"
    }
}
