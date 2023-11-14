//
//  DeviceService.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Foundation
import ShellOut
import AppKit
import UserNotifications

protocol DeviceServiceProtocol {
    static func getIOSDevices() throws -> [Device]
    static func checkXcodeSetup() -> Bool
    static func deleteSimulator(uuid: String) throws
    
    static func toggleA11y(device: Device) throws
    static func getAndroidDevices() throws -> [Device]
    static func sendText(device: Device, text: String) throws
    static func checkAndroidSetup() throws -> String
    
    static func focusDevice(_ device: Device)
    static func runCustomCommand(_ device: Device, command: Command) throws
    static func getCustomCommands(platform: Platform) -> [Command]
    static func getCustomCommand(platform: Platform, commandName: String) -> Command?
    static func showSuccessMessage(title: String, message: String)
}

class DeviceService: DeviceServiceProtocol {
    
    private static let queue = DispatchQueue(label: "com.MiniSim.DeviceService", qos: .userInteractive)
    private static let deviceBootedError = "Unable to boot device in current state: Booted"
    
    private static let derivedDataLocation = "~/Library/Developer/Xcode/DerivedData"
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
    }
    
    private enum BundleURL: String {
        case emulator = "qemu-system-aarch64"
        case simulator = "Simulator.app"
    }
    
    static func getCustomCommands(platform: Platform) -> [Command] {
        guard let commandsData = UserDefaults.standard.commands else { return [] }
        guard let commands = try? JSONDecoder().decode([Command].self, from: commandsData) else {
            return []
        }
        
        return commands.filter({ $0.platform == platform })
    }
    
    static func getCustomCommand(platform: Platform, commandName: String) -> Command? {
        let commands = getCustomCommands(platform: platform)
        return commands.first(where: { $0.name == commandName })
    }
    
    
    static func runCustomCommand(_ device: Device, command: Command) throws {
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
    
    static func focusDevice(_ device: Device) {
        queue.async {
            
            let runningApps = NSWorkspace.shared.runningApplications.filter({$0.activationPolicy == .regular})
            
            if let uuid = device.ID, device.platform == .ios {
                try? Self.launchSimulatorApp(uuid: uuid)
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
                    
                    if !Self.matchDeviceTitle(windowTitle: windowTitle, device: device) {
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
    }
    
    private static func matchDeviceTitle(windowTitle: String, device: Device) -> Bool {
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
    
    static func showSuccessMessage(title: String, message: String) {
        UNUserNotificationCenter.showNotification(title: title, body: message)
        NotificationCenter.default.post(name: .commandDidSucceed, object: nil)
    }
    
    static func getAllDevices(
        android: Bool,
        iOS: Bool,
        completionQueue: DispatchQueue = .main,
        completion: @escaping ([Device], Error?) -> ()
    ) {
        queue.async {
            do {
                var devicesArray: [Device] = []
                
                if android {
                    try devicesArray.append(contentsOf: getAndroidDevices())
                }
                
                if iOS {
                    try devicesArray.append(contentsOf: getIOSDevices())
                }
                
                completionQueue.async {
                    completion(devicesArray, nil)
                }
            } catch {
                completionQueue.async {
                    completion([], error)
                }
            }
        }
    }
    
    private static func launch(device: Device) throws {
        switch device.platform {
        case .ios:
            try launchDevice(uuid: device.ID ?? "")
        case .android:
            try launchDevice(name: device.name)
        }
    }
    
    static func launch(device: Device, completionQueue: DispatchQueue = .main, completion: @escaping (Error?) -> Void) {
        self.queue.async {
            do {
                try self.launch(device: device)
                completionQueue.async {
                    completion(nil)
                }
            }
            catch {
                if error.localizedDescription.contains(deviceBootedError) {
                    return
                }
                completionQueue.async {
                    completion(error)
                }
            }
        }
    }
    
    static func togglePinned(device: Device) {
        var pinnedDevices: [String]?
        switch device.platform {
        case .android:
            pinnedDevices = UserDefaults.standard.pinnedAndroidEmulators
            var dedupedPinnedDevices = Set(pinnedDevices ?? [])
            if dedupedPinnedDevices.contains(device.name) {
                dedupedPinnedDevices.remove(device.name)
            } else {
                dedupedPinnedDevices.insert(device.name)
            }
            UserDefaults.standard.pinnedAndroidEmulators = Array(dedupedPinnedDevices)
        case .ios:
            pinnedDevices = UserDefaults.standard.pinnediOSSimulators
            var dedupedPinnedDevices = Set(pinnedDevices ?? [])
            if dedupedPinnedDevices.contains(device.name) {
                dedupedPinnedDevices.remove(device.name)
            } else {
                dedupedPinnedDevices.insert(device.name)
            }
            UserDefaults.standard.pinnediOSSimulators = Array(dedupedPinnedDevices)
        }
    }
}

// MARK: iOS Methods
extension DeviceService {
    
    static private func parseIOSDevices(result: [String]) -> [Device] {
        var devices: [Device] = []
        var osVersion = ""
        let pinnediOSSimulators: [String] = UserDefaults.standard.pinnediOSSimulators ?? []
        result.forEach { line in
            if let currentOs = line.match("-- (.*?) --").first, currentOs.count > 0 {
                osVersion = currentOs[1]
            }
            if let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\) (\\(.*?)\\)").first {
                let deviceName = device[1].trimmingCharacters(in: .whitespacesAndNewlines)
                devices.append(
                    Device(
                        name: deviceName,
                        version: osVersion,
                        ID: device[4],
                        booted: device[5].contains("Booted"),
                        platform: .ios,
                        pinned: pinnediOSSimulators.contains(deviceName)
                    )
                )
            }
        }
        return devices
    }
    
    static func clearDerivedData(completionQueue: DispatchQueue = .main, completion: @escaping (String, Error?) -> Void) {
        self.queue.async {
            do {
                let amountCleared = try? shellOut(to: "du -sh \(derivedDataLocation)").match(###"\d+\.?\d+\w+"###).first?.first
                try shellOut(to: "rm -rf \(derivedDataLocation)")
                completionQueue.async {
                    completion(amountCleared ?? "", nil)
                }
            }
            catch {
                completionQueue.async {
                    completion("", error)
                }
            }
        }
    }
    
    static func getIOSDevices() throws -> [Device] {
        let output = try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "list", "devices", "available"])
        let splitted = output.components(separatedBy: "\n")
        
        return parseIOSDevices(result: splitted)
    }
    
    static func launchSimulatorApp(uuid: String) throws {
        let isSimulatorRunning = NSWorkspace.shared.runningApplications.contains(where: {$0.bundleIdentifier == "com.apple.iphonesimulator"})
        
        if !isSimulatorRunning {
            guard let activeDeveloperDir = try? shellOut(to: ProcessPaths.xcodeSelect.rawValue, arguments: ["-p"]).trimmingCharacters(in: .whitespacesAndNewlines) else {
                throw DeviceError.XCodeError
            }
            try shellOut(to: "\(activeDeveloperDir)/Applications/Simulator.app/Contents/MacOS/Simulator", arguments: ["--args", "-CurrentDeviceUDID", uuid])
        }
    }
    
    private static func launchDevice(uuid: String) throws {
        do {
            try self.launchSimulatorApp(uuid: uuid)
            try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "boot", uuid])
        } catch {
            if !error.localizedDescription.contains(deviceBootedError) {
                throw error
            }
        }
    }
    
    static func deleteSimulator(uuid: String) throws {
        try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "delete", uuid])
    }
    
    static func handleiOSAction(device: Device, commandTag: SubMenuItems.Tags, itemName: String) {
        switch commandTag {
        case .copyName:
            NSPasteboard.general.copyToPasteboard(text: device.name)
            DeviceService.showSuccessMessage(title: "Device name copied to clipboard!", message: device.name)
        case .copyID:
            if let deviceID = device.ID {
                NSPasteboard.general.copyToPasteboard(text: deviceID)
                DeviceService.showSuccessMessage(title: "Device ID copied to clipboard!", message: deviceID)
            }
        case .togglePinned:
            DeviceService.togglePinned(device: device)
            
        case .delete:
            guard let deviceID = device.ID else { return }
            if !NSAlert.showQuestionDialog(title: "Are you sure?", message: "Are you sure you want to delete this Simulator?") {
                return
            }
            queue.async {
                do {
                    try DeviceService.deleteSimulator(uuid: deviceID)
                    DeviceService.showSuccessMessage(title: "Simulator deleted!", message: deviceID)
                    NotificationCenter.default.post(name: .deviceDeleted, object: nil)
                } catch {
                    NSAlert.showError(message: error.localizedDescription)
                }
            }
        case .customCommand:
            guard let command = DeviceService.getCustomCommand(platform: .ios, commandName: itemName) else {
                return
            }
            queue.async {
                do {
                    try DeviceService.runCustomCommand(device, command: command)
                } catch {
                    NSAlert.showError(message: error.localizedDescription)
                }
            }
        default:
            break
        }
    }
    
}


// MARK: Android Methods
extension DeviceService {
    private static func launchDevice(name: String, additionalArguments: [String] = []) throws {
        let emulatorPath = try ADB.getEmulatorPath()
        var arguments = ["@\(name)"]
        let formattedArguments = additionalArguments.filter({ !$0.isEmpty }).map {
            if $0.hasPrefix("-") {
                return $0
            }
            return "-\($0)"
        }
        arguments.append(contentsOf: getAndroidLaunchParams())
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
    
    private static func getAndroidLaunchParams() -> [String] {
        guard let paramData = UserDefaults.standard.parameters else { return [] }
        guard let parameters = try? JSONDecoder().decode([Parameter].self, from: paramData) else {
            return []
        }
        
        return parameters.filter({ $0.enabled }).map({ $0.command })
    }
    
    static func getAndroidDevices() throws -> [Device] {
        let emulatorPath = try ADB.getEmulatorPath()
        let adbPath = try ADB.getAdbPath()
        let output = try shellOut(to: emulatorPath, arguments: ["-list-avds"])
        let splitted = output.components(separatedBy: "\n")
        let pinnedAndroidEmulators: [String] = UserDefaults.standard.pinnedAndroidEmulators ?? []
        
        return splitted.filter({ !$0.isEmpty }).map {
            let adbId = try? ADB.getAdbId(for: $0, adbPath: adbPath)
            return Device(name: $0, ID: adbId, booted: adbId != nil, platform: .android, pinned: pinnedAndroidEmulators.contains($0))
        }
    }
    
    static func toggleA11y(device: Device) throws {
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
    
    static func sendText(device: Device, text: String) throws {
        let adbPath = try ADB.getAdbPath()
        guard let deviceId = device.ID else {
            throw DeviceError.deviceNotFound
        }
        
        let formattedText = text.replacingOccurrences(of: " ", with: "%s").replacingOccurrences(of: "'", with: "''")
        
        try shellOut(to: "\(adbPath) -s \(deviceId) shell input text \"\(formattedText)\"")
    }
    
    static func handleAndroidAction(device: Device, commandTag: SubMenuItems.Tags, itemName: String) {
        queue.async {
            do {
                switch commandTag {
                case .coldBoot:
                    try DeviceService.launchDevice(name: device.name, additionalArguments:["-no-snapshot"])
                    
                case .noAudio:
                    try DeviceService.launchDevice(name: device.name, additionalArguments:["-no-audio"])
                    
                case .toggleA11y:
                    try DeviceService.toggleA11y(device: device)
                    
                case .copyID:
                    if let deviceId = device.ID {
                        NSPasteboard.general.copyToPasteboard(text: deviceId)
                        DeviceService.showSuccessMessage(title: "Device ID copied to clipboard!", message: deviceId)
                    }
                    
                case .copyName:
                    NSPasteboard.general.copyToPasteboard(text: device.name)
                    DeviceService.showSuccessMessage(title: "Device name copied to clipboard!", message: device.name)
                    
                case .togglePinned:
                    DeviceService.togglePinned(device: device)
                    
                case .paste:
                    guard let clipboard = NSPasteboard.general.pasteboardItems?.first?.string(forType: .string) else { break }
                    try DeviceService.sendText(device: device, text: clipboard)
                    
                case .customCommand:
                    if let command = DeviceService.getCustomCommand(platform: .android, commandName: itemName) {
                        try DeviceService.runCustomCommand(device, command: command)
                    }
                default:
                    break
                }
            }
            catch {
                NSAlert.showError(message: error.localizedDescription)
            }
        }
    }
}
