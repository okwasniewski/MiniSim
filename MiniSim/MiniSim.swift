//
//  StatusBarController.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit
import Preferences
import SwiftUI
import UserNotifications


class MiniSim: NSObject {
    private var menu: Menu!
    
    @objc var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private var isOnboardingFinishedObserver: NSKeyValueObservation?
    private var menuImageObserver: NSKeyValueObservation?
    
    private var menuImagesObserved: [String] = []
    
    private lazy var onboarding = Onboarding()
    
    override init() {
        super.init()
        
        settingsController.window?.delegate = self
        
        setDefaultValues()
        initObservers()
        
        setup()
    }
    
    deinit {
        isOnboardingFinishedObserver?.invalidate()
        menuImageObserver?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .commandDidSucceed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .deviceDeleted, object: nil)
    }
    
    private lazy var settingsController = SettingsWindowController(
        panes: [
            Settings.Pane(
                identifier: .preferences,
                title: "Preferences",
                toolbarIcon: NSImage(systemSymbolName: "gear", accessibilityDescription: "") ?? NSImage()
            ) {
                Preferences()
            },
            Settings.Pane(
                identifier: .devices,
                title: "Devices",
                toolbarIcon: NSImage(systemSymbolName: "iphone", accessibilityDescription: "") ?? NSImage()
            ) {
                Devices()
            },
            Settings.Pane(
                identifier: .commands,
                title: "Commands",
                toolbarIcon: NSImage(systemSymbolName: "command", accessibilityDescription: "") ?? NSImage()
            ) {
                CustomCommands()
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
        animated: false
    )
    
    func open() {
        self.statusItem.button?.performClick(self)
    }
    
    private func setup() {
        if !UserDefaults.standard.isOnboardingFinished {
            onboarding.show()
            return
        }
        menu = Menu()
        statusItem.menu = menu
        setMenuImage()
        populateSections()
        
        menu.getDevices()
    }
    
    private func initObservers() {
        isOnboardingFinishedObserver = UserDefaults.standard.observe(\.isOnboardingFinished, options: .new) { _, _ in
            if UserDefaults.standard.isOnboardingFinished == true {
                self.setup()
                self.onboarding.showPopOver(button: self.statusItem.button)
            }
        }
        menuImageObserver = UserDefaults.standard.observe(\.menuImage, options: .new) { _,_ in
            self.setMenuImage()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(toggleSuccessCheckmark), name: .commandDidSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceDeleted), name: .deviceDeleted, object: nil)
    }
    
    private func setDefaultValues() {
        UserDefaults.standard.register(defaults: [
            UserDefaults.Keys.enableAndroidEmulators: true,
            UserDefaults.Keys.enableiOSSimulators: true
        ])
    }
    
    private func setMenuImage() {
        if let button = statusItem.button {
            button.toolTip = "MiniSim"
            let itemImage = NSImage(named: UserDefaults.standard.menuImage)
            if (!menuImagesObserved.contains(UserDefaults.standard.menuImage)) {
                itemImage?.size = NSSize(
                    width:  (itemImage?.size.width  ?? 16) * 0.78,
                    height: (itemImage?.size.height ?? 16) * 0.78)
                menuImagesObserved.append(UserDefaults.standard.menuImage)
            }
            itemImage?.isTemplate = true
            button.image = itemImage
        }
    }
    
    @objc private func toggleSuccessCheckmark() {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                let itemImage = NSImage(named: "success_action")
                itemImage?.size = NSSize(width: 9, height: 15)
                itemImage?.isTemplate = true
                button.image = itemImage
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.setMenuImage()
        }
    }
    
    @objc private func handleDeviceDeleted() {
        menu.getDevices()
    }
    
    @objc func menuItemAction(_ sender: NSMenuItem) {
        if let tag = MenuSections(rawValue: sender.tag) {
            switch tag {
            case .preferences:
                settingsController.show()
            case .quit:
                NSApp.terminate(sender)
            case .clearDerrivedData:
                let shouldDelete = NSAlert.showQuestionDialog(title: "Are you sure?", message: "This action will delete derived data from your computer.")
                if !shouldDelete {
                    return
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let amountCleared = try DeviceService.clearDerivedData()
                        UNUserNotificationCenter.showNotification(title: "Derived data has been cleared!", body: "Removed \(amountCleared) of data")
                        NotificationCenter.default.post(name: .commandDidSucceed, object: nil)
                    } catch {
                        NSAlert.showError(message: error.localizedDescription)
                    }
                }
            default:
                break
            }
            
        }
    }
    
    private func populateSections() {
        if !menu.items.isEmpty {
            return
        }
        MenuSections.allCases.forEach { item in
            if (!item.attachItem) {
                return
            }
            
            let menuItem = item.menuItem
            if menuItem.tag >= MenuSections.clearDerrivedData.rawValue {
                menuItem.action = #selector(menuItemAction)
                menuItem.target = self
            } else {
                menuItem.isEnabled = false
            }
            menu.addItem(menuItem)
        }
    }
}


extension MiniSim: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
