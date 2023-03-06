//
//  DeviceService.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Foundation
import ShellOut
import AppKit

protocol DeviceServiceProtocol {
    func launchDevice(uuid: String) throws
    func getIOSDevices() throws -> [Device]
    
    func launchDevice(name: String, additionalArguments: [String]) throws
    func toggleA11y(device: Device) throws
    func getAndroidDevices() throws -> [Device]
    func sendText(device: Device, text: String) throws
    
    func focusDevice(_ device: Device)
}

class DeviceService: DeviceServiceProtocol {
    private let deviceBootedError = "Unable to boot device in current state: Booted"
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
    }
    
    private enum BundleURL: String {
        case emulator = "qemu-system-aarch64"
        case simulator = "Simulator.app"
    }
    
    func focusDevice(_ device: Device) {
        let runningApps = NSWorkspace.shared.runningApplications.filter({$0.activationPolicy == .regular})
        
        if let uuid = device.ID, !device.isAndroid {
            try? launchSimulatorApp(uuid: uuid)
        }
        
        for app in runningApps {
            guard
                let bundleURL = app.bundleURL?.absoluteString,
                (bundleURL.contains(BundleURL.simulator.rawValue) || bundleURL.contains(BundleURL.emulator.rawValue)) else {
                continue
            }
            let isAndroid = bundleURL.contains(BundleURL.emulator.rawValue)
            
            for window in AccessibilityElement.allWindowsForPID(app.processIdentifier) {
                guard let windowTitle = window.attribute(key: .title, type: String.self), !windowTitle.isEmpty else {
                    continue
                }
                
                if !matchDeviceTitle(windowTitle: windowTitle, device: device) {
                    continue
                }
                
                if isAndroid {
                    AccessibilityElement.forceFocus(pid: app.processIdentifier)
                } else {
                    window.performAction(key: kAXRaiseAction)
                    app.activate(options: [.activateIgnoringOtherApps])
                }
            }
        }
    }
    
    private func matchDeviceTitle(windowTitle: String, device: Device) -> Bool {
        if device.isAndroid {
            let deviceName = windowTitle.match(#"(?<=- ).*?(?=:)"#).first?.first
            return deviceName == device.name
        }
        
        let deviceName = windowTitle.match(#"^[^–]*"#).first?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return deviceName == device.name
    }
}

// MARK: iOS Methods
extension DeviceService {
    
    private func parseIOSDevices(result: [String]) -> [Device] {
        var devices: [Device] = []
        result.forEach { line in
            let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\) (\\(.*?)\\)")
            if (!device.isEmpty) {
                let firstDevice = device[0]
                devices.append(
                    Device(
                        name: firstDevice[1].trimmingCharacters(in: .whitespacesAndNewlines),
                        version: firstDevice[3],
                        ID: firstDevice[4],
                        booted: firstDevice[5].contains("Booted")
                    )
                )
            }
        }
        return devices
    }
    
    func getIOSDevices() throws -> [Device] {
        let output = try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "list", "devices", "available"])
        let splitted = output.components(separatedBy: "\n")
        
        return parseIOSDevices(result: splitted)
    }
    
    func launchSimulatorApp(uuid: String) throws {
        let isSimulatorRunning = NSWorkspace.shared.runningApplications.contains(where: {$0.bundleIdentifier == "com.apple.iphonesimulator"})
        
        if !isSimulatorRunning {
            guard let activeDeveloperDir = try? shellOut(to: ProcessPaths.xcodeSelect.rawValue, arguments: ["-p"]).trimmingCharacters(in: .whitespacesAndNewlines) else {
                throw DeviceError.XCodeError
            }
            try shellOut(to: "\(activeDeveloperDir)/Applications/Simulator.app/Contents/MacOS/Simulator", arguments: ["--args", "-CurrentDeviceUDID", uuid])
        }
    }
    
    func launchDevice(uuid: String) throws {
        do {
            try launchSimulatorApp(uuid: uuid)
            try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "boot", uuid])
        } catch {
            if !error.localizedDescription.contains(deviceBootedError) {
                throw error
            }
        }
    }
    
}


// MARK: Android Methods
extension DeviceService {
    func launchDevice(name: String, additionalArguments: [String]) throws {
        let emulatorPath = try ADB.getEmulatorPath()
        var arguments = ["@\(name)"]
        arguments.append(contentsOf: additionalArguments)
        try shellOut(to: emulatorPath, arguments: arguments)
    }
    
    func getAndroidDevices() throws -> [Device] {
        let emulatorPath = try ADB.getEmulatorPath()
        let adbPath = try ADB.getAdbPath()
        let output = try shellOut(to: emulatorPath, arguments: ["-list-avds"])
        let splitted = output.components(separatedBy: "\n")
        
        return splitted.filter({ !$0.isEmpty }).map {
            let adbId = try? ADB.getAdbId(for: $0, adbPath: adbPath)
            return Device(name: $0, ID: adbId, booted: adbId != nil, isAndroid: true)
        }
    }
    
    func toggleA11y(device: Device) throws {
        let adbPath = try ADB.getAdbPath()
        guard let adbId = device.ID else {
            throw DeviceError.deviceNotFound
        }
        
        if ADB.isAccesibilityOn(deviceId: adbId, adbPath: adbPath) {
            _ = try? shellOut(to: "\(adbPath) -s \(adbId) shell settings put secure enabled_accessibility_services \(ADB.talkbackOff)")
        } else {
            _ = try? shellOut(to: "\(adbPath) -s \(adbId) shell settings put secure enabled_accessibility_services \(ADB.talkbackOn)")
        }
    }
    
    func sendText(device: Device, text: String) throws {
        let adbPath = try ADB.getAdbPath()
        guard let deviceId = device.ID else {
            throw DeviceError.deviceNotFound
        }
        
        let formattedText = text.replacingOccurrences(of: " ", with: "%s").replacingOccurrences(of: "'", with: "''")
        
        try shellOut(to: "\(adbPath) -s \(deviceId) shell input text \"\(formattedText)\"")
    }
}
