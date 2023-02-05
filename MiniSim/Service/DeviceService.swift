//
//  DeviceService.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Foundation
import ShellOut

protocol DeviceServiceProtocol {
    // iOS Device
    func launchDevice(uuid: String, _ completion: @escaping (LaunchDeviceResult) -> Void)
    func getIOSDevices(_ completion: @escaping (GetDevicesResult) -> Void)
    
    //Android Device
    func launchDevice(name: String, additionalArguments: [String], _ completion: @escaping (LaunchDeviceResult) -> Void)
    func toggleA11y(device: Device)
    func getAndroidDevices(_ completion: @escaping (GetDevicesResult) -> Void)
    
    typealias GetDevicesResult = Result<[Device], Error>
    typealias LaunchDeviceResult = Result<Void, Error>
}

class DeviceService: DeviceServiceProtocol {
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
    }
}

// iOS Methods
extension DeviceService {
    
    func getIOSDevices(_ completion: @escaping (GetDevicesResult) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var output = ""
            do {
                output = try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "list", "devices", "available"])
            } catch {
                completion(.failure(error))
                return
            }
            
            let splitted = output.components(separatedBy: "\n")
            
            var devices: [Device] = []
            splitted.forEach { line in
                let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\)")
                if (!device.isEmpty) {
                    let firstDevice = device[0]
                    devices.append(
                        Device(
                            name: firstDevice[1].trimmingCharacters(in: .whitespacesAndNewlines),
                            version: firstDevice[3],
                            uuid: firstDevice[4]
                        )
                    )
                }
            }
            
            completion(.success(devices))
        }
    }
    
    func launchDevice(uuid: String, _ completion: @escaping (LaunchDeviceResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let activeDeveloperDir = try shellOut(to: ProcessPaths.xcodeSelect.rawValue, arguments: ["-p"]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                try shellOut(to: "\(activeDeveloperDir)/Applications/Simulator.app/Contents/MacOS/Simulator", arguments: ["--args", "-CurrentDeviceUDID", uuid])
                
                try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "boot", uuid])
                
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    
}


// Android methods
extension DeviceService {
    func launchDevice(name: String, additionalArguments: [String] = [], _ completion: @escaping (LaunchDeviceResult) -> Void) {
        
        var arguments = ["@\(name)"]
        arguments.append(contentsOf: additionalArguments)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let emulatorPath = try ADB.getEmulatorPath()
                try shellOut(to: emulatorPath, arguments: arguments)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getAndroidDevices(_ completion: @escaping (GetDevicesResult) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var output = ""
            do {
                let emulatorPath = try ADB.getEmulatorPath()
                output = try shellOut(to: emulatorPath, arguments: ["-list-avds"])
            } catch {
                completion(.failure(error))
                return
            }
            
            let splitted = output.components(separatedBy: "\n")
            let devices = splitted.filter({ !$0.isEmpty }).map {
                return Device(name: $0, isAndroid: true)
            }
            completion(.success(devices))
        }
    }
    
    func toggleA11y(device: Device) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let adbPath = try? ADB.getAdbPath() else { return }
            
            guard let deviceId = ADB.getAdbId(for: device.name, adbPath: adbPath) else { return }
            
            if ADB.isAccesibilityOn(deviceId: deviceId, adbPath: adbPath) {
                _ = try? shellOut(to: "\(adbPath) -s \(deviceId) shell settings put secure enabled_accessibility_services \(ADB.talkbackOff)")
            } else {
                _ = try? shellOut(to: "\(adbPath) -s \(deviceId) shell settings put secure enabled_accessibility_services \(ADB.talkbackOn)")
            }
        }
    }
}
