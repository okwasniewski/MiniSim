//
//  DeviceService.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Foundation

enum DeviceType: String {
    case iOS = "iOS"
    case Android = "Android"
}

protocol DeviceServiceProtocol {
    // iOS Device
    func launchDevice(uuid: String, _ completion: @escaping (LaunchDeviceResult) -> Void)
    
    //Android Device
    func launchDevice(name: String, _ completion: @escaping (LaunchDeviceResult) -> Void)
    
    func getDevices(deviceType: DeviceType, _ completion: @escaping (GetDevicesResult) -> Void)
    
    typealias GetDevicesResult = Result<[Device], Error>
    typealias LaunchDeviceResult = Result<Void, Error>
}

class DeviceService: DeviceServiceProtocol {
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case xcodeSelect = "/usr/bin/xcode-select"
        case emulator = "/Android/sdk/emulator/emulator"
    }
    
    @discardableResult private func runProcess(processURL: String, arguments: [String], waitUntilExit: Bool = true) throws -> String {
        var fileURL = processURL
        
        if processURL == ProcessPaths.emulator.rawValue {
            let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
            guard let libraryDirectory = libraryDirectory.first else {
                return ""
            }
            fileURL = libraryDirectory + fileURL
        }
        
        let output = try Process.runProcess(fileURL: fileURL, arguments: arguments, waitUntilExit: waitUntilExit)
        
        return output
    }
    
    // iOS device
    func launchDevice(uuid: String, _ completion: @escaping (LaunchDeviceResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let activeDeveloperDir = try self.runProcess(
                    processURL: ProcessPaths.xcodeSelect.rawValue,
                    arguments: ["-p"]
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                
                try self.runProcess(
                    processURL: "\(activeDeveloperDir)/Applications/Simulator.app/Contents/MacOS/Simulator",
                    arguments: ["--args", "-CurrentDeviceUDID", uuid],
                    waitUntilExit: false
                )
                
                try self.runProcess(
                    processURL: ProcessPaths.xcrun.rawValue,
                    arguments: ["simctl", "boot", uuid],
                    waitUntilExit: false
                )
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Android device
    func launchDevice(name: String, _ completion: @escaping (LaunchDeviceResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.runProcess(processURL: ProcessPaths.emulator.rawValue, arguments: ["@\(name)"], waitUntilExit: false)
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
                output = try runProcess(processURL: ProcessPaths.xcrun.rawValue, arguments: ["xctrace", "list", "devices"])
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
                output = try runProcess(processURL: ProcessPaths.emulator.rawValue, arguments: ["-list-avds"])
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
    
    static func getSystemImageFromName(name: String) -> String {
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
