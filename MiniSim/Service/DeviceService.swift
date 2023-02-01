//
//  DeviceService.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Foundation
import ShellOut

enum DeviceType: String {
    case iOS = "iOS"
    case Android = "Android"
}

protocol DeviceServiceProtocol {
    // iOS Device
    func launchDevice(uuid: String, _ completion: @escaping (LaunchDeviceResult) -> Void)
    
    //Android Device
    func launchDevice(name: String, additionalArguments: [String], _ completion: @escaping (LaunchDeviceResult) -> Void)
    func toggleA11y(device: Device)
    
    func getDevices(deviceType: DeviceType, _ completion: @escaping (GetDevicesResult) -> Void)
    
    typealias GetDevicesResult = Result<[Device], Error>
    typealias LaunchDeviceResult = Result<Void, Error>
}

class DeviceService: DeviceServiceProtocol {
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
    }
    
    // iOS device
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
    
    // Android device
    func launchDevice(name: String, additionalArguments: [String] = [], _ completion: @escaping (LaunchDeviceResult) -> Void) {
        
        var arguments = ["@\(name)"]
        arguments.append(contentsOf: additionalArguments)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let emulatorPath = try Adb.getEmulatorPath()
                try shellOut(to: emulatorPath, arguments: arguments)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getDevices(deviceType: DeviceType, _ completion: @escaping (GetDevicesResult) -> Void) {
        var output = ""
        
        switch deviceType {
        case .iOS:
            do {
                output = try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["xctrace", "list", "devices"])
            } catch {
                completion(.failure(error))
                return
            }
            
            let splitted = output.components(separatedBy: "\n")
            
            var isSimulator = false
            
            var devices: [Device] = []
            splitted.forEach { line in
                if line == "== Simulators ==" {
                    isSimulator = true
                }
                
                let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\)")
                if (!device.isEmpty && isSimulator) {
                    let firstDevice = device[0]
                    devices.append(
                        Device(
                            name: firstDevice[1],
                            version: firstDevice[3],
                            uuid: firstDevice[4]
                        )
                    )
                }
            }
            
            completion(.success(devices))
            
        case .Android:
            do {
                let emulatorPath = try Adb.getEmulatorPath()
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
            guard let adbPath = try? Adb.getAdbPath() else { return }
            
            guard let deviceId = Adb.getAdbId(for: device.name, adbPath: adbPath) else { return }
            
            if Adb.isAccesibilityOn(deviceId: deviceId, adbPath: adbPath) {
                _ = try? shellOut(to: "\(adbPath) -s \(deviceId) shell settings put secure enabled_accessibility_services \(Adb.talkbackOff)")
            } else {
                _ = try? shellOut(to: "\(adbPath) -s \(deviceId) shell settings put secure enabled_accessibility_services \(Adb.talkbackOn)")
            }
        }
    }
    
    static func getSystemImageFromName(name: String) -> String {
        if name.contains("Apple TV") {
            return "appletv.fill"
        }
        
        if (name.contains("iPad") || name.contains("Tablet")) {
            return "ipad.landscape"
        }
        
        if name.contains("Watch") {
            return "applewatch"
        }
        
        if name.contains("TV") {
            return "tv"
        }
        
        return "iphone"
    }
}
