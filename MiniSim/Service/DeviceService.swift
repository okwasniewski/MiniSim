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
    static func checkXcodeSetup() -> Bool
    func deleteSimulator(uuid: String) throws
    static func clearDerivedData() throws -> String
    
    func launchDevice(name: String, additionalArguments: [String]) throws
    func toggleA11y(device: Device) throws
    func getAndroidDevices() throws -> [Device]
    func sendText(device: Device, text: String) throws
    static func checkAndroidSetup() throws -> String
    
    func focusDevice(_ device: Device)
    func runCustomCommand(_ device: Device, command: Command) throws
}

class DeviceService: DeviceServiceProtocol {
    private let deviceBootedError = "Unable to boot device in current state: Booted"
    
    private static let derivedDataLocation = "~/Library/Developer/Xcode/DerivedData"
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
    }
    
    private enum BundleURL: String {
        case emulator = "qemu-system-aarch64"
        case simulator = "Simulator.app"
    }
    
    func runCustomCommand(_ device: Device, command: Command) throws {
        var commandToExecute = command.command
            .replacingOccurrences(of: Variables.device_name.rawValue, with: device.name)
        
        let deviceID = device.ID ?? ""
        
        if (command.platform == .android) {
            commandToExecute = try commandToExecute
                .replacingOccurrences(of: Variables.adb_path.rawValue, with: ADB.getAdbPath())
                .replacingOccurrences(of: Variables.adb_id.rawValue, with: deviceID)
                .replacingOccurrences(of: Variables.android_home_path.rawValue, with: ADB.getAndroidHome())
            
        } else {
            commandToExecute = commandToExecute
                .replacingOccurrences(of: Variables.uuid.rawValue, with: deviceID)
                .replacingOccurrences(of: Variables.xcrun_path.rawValue, with: ProcessPaths.xcrun.rawValue)
        }
        
        do {
            try shellOut(to: commandToExecute)
            if (command.bootsDevice ?? false && command.platform == .ios) {
                try? launchSimulatorApp(uuid: deviceID)
            }
            NotificationCenter.default.post(name: .commandDidSucceed, object: nil)
        } catch {
            throw CustomCommandError.commandError(errorMessage: error.localizedDescription)
        }
    }
    
    func focusDevice(_ device: Device) {
        let runningApps = NSWorkspace.shared.runningApplications.filter({$0.activationPolicy == .regular})
        
        if let uuid = device.ID, device.platform == .ios {
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
        if device.platform == .android {
            let deviceName = windowTitle.match(#"(?<=- ).*?(?=:)"#).first?.first
            return deviceName == device.name
        }
        
        let deviceName = windowTitle.match(#"^[^–]*"#).first?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return deviceName == device.name
    }
    
    static func checkXcodeSetup() -> Bool {
        return FileManager.default.fileExists(atPath: ProcessPaths.xcrun.rawValue)
    }
    
    static func checkAndroidSetup() throws -> String {
        let emulatorPath = try ADB.getAndroidHome()
        try ADB.checkAndroidHome(path: emulatorPath)
        return emulatorPath
    }
}

// MARK: iOS Methods
extension DeviceService {
    
    private func parseIOSDevices(result: [String]) -> [Device] {
        var devices: [Device] = []
        var osVersion = ""
        result.forEach { line in
            if let currentOs = line.match("-- (.*?) --").first, currentOs.count > 0 {
                osVersion = currentOs[1]
            }
            if let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\) (\\(.*?)\\)").first {
                devices.append(
                    Device(
                        name: device[1].trimmingCharacters(in: .whitespacesAndNewlines),
                        version: osVersion,
                        ID: device[4],
                        booted: device[5].contains("Booted"),
                        platform: .ios
                    )
                )
            }
        }
        return devices
    }
    
    static func clearDerivedData() throws -> String {
        let amountCleared = try? shellOut(to: "du -sh \(derivedDataLocation)").match(###"\d+\.?\d+\w+"###).first?.first
        try shellOut(to: "rm -rf \(derivedDataLocation)")
        return amountCleared ?? ""
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
    
    func deleteSimulator(uuid: String) throws {
        try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "delete", uuid])
    }
    
}


// MARK: Android Methods
extension DeviceService {
    func launchDevice(name: String, additionalArguments: [String]) throws {
        let emulatorPath = try ADB.getEmulatorPath()
        var arguments = ["@\(name)"]
        let formattedArguments = additionalArguments.filter({ !$0.isEmpty }).map {
            if $0.hasPrefix("-") {
                return $0
            }
            return "-\($0)"
        }
        arguments.append(contentsOf: formattedArguments)
        do {
            try shellOut(to: emulatorPath, arguments: arguments)
        } catch {
            // Ignore force qutting emulator (CMD + Q)
            if error.localizedDescription.contains("unexpected system image feature string") {
                return
            }
            throw error
        }
    }
    
    func getAndroidDevices() throws -> [Device] {
        let emulatorPath = try ADB.getEmulatorPath()
        let adbPath = try ADB.getAdbPath()
        let output = try shellOut(to: emulatorPath, arguments: ["-list-avds"])
        let splitted = output.components(separatedBy: "\n")
        
        return splitted.filter({ !$0.isEmpty }).map {
            let adbId = try? ADB.getAdbId(for: $0, adbPath: adbPath)
            return Device(name: $0, ID: adbId, booted: adbId != nil, platform: .android)
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
