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
    func getAdbId(device: Device) throws -> String
    func sendText(device: Device, text: String) throws
}

class DeviceService: DeviceServiceProtocol {
    private let deviceBootedError = "Unable to boot device in current state: Booted"
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
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
        print(devices)
        return devices
    }
    
    func getIOSDevices() throws -> [Device] {
        let output = try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "list", "devices", "available"])
        let splitted = output.components(separatedBy: "\n")
        
        return parseIOSDevices(result: splitted)
    }
    
    func launchDevice(uuid: String) throws {
        guard let activeDeveloperDir = try? shellOut(to: ProcessPaths.xcodeSelect.rawValue, arguments: ["-p"]).trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw DeviceError.XCodeError
        }
        try shellOut(to: "open \(activeDeveloperDir)/Applications/Simulator.app")
        do {
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
            return
        }
        
        if ADB.isAccesibilityOn(deviceId: adbId, adbPath: adbPath) {
            _ = try? shellOut(to: "\(adbPath) -s \(adbId) shell settings put secure enabled_accessibility_services \(ADB.talkbackOff)")
        } else {
            _ = try? shellOut(to: "\(adbPath) -s \(adbId) shell settings put secure enabled_accessibility_services \(ADB.talkbackOn)")
        }
    }
    
    func getAdbId(device: Device) throws -> String {
        let adbPath = try ADB.getAdbPath()
        return try ADB.getAdbId(for: device.name, adbPath: adbPath)
    }
    
    func sendText(device: Device, text: String) throws {
        let adbPath = try ADB.getAdbPath()
        let deviceId = try ADB.getAdbId(for: device.name, adbPath: adbPath)
        let formattedText = text.replacingOccurrences(of: " ", with: "%s").replacingOccurrences(of: "'", with: "''")
        
        try shellOut(to: "\(adbPath) -s \(deviceId) shell input text \"\(formattedText)\"")
    }
}
