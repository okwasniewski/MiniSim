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
    func launchDevice(uuid: String) -> Void
    
    //Android Device
    func launchDevice(name: String) -> Void
    
    func getDevices(deviceType: DeviceType, _ completion: @escaping (GetDevicesResult) -> Void)
    
    typealias GetDevicesResult = Result<[Device], Error>
}

class DeviceService: DeviceServiceProtocol {
    
    private enum ProcessPaths: String {
        case xcrun = "/usr/bin/xcrun"
        case emulator = "/Android/sdk/emulator/emulator"
    }
    
    private func getStringOutput(_ pipe: Pipe) -> String {
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        return output
    }
    
    private func runProcess(processURL: ProcessPaths, arguments: [String], standardOutput: Pipe? = nil) throws -> Void {
        var fileURL = processURL.rawValue
        
        if processURL == ProcessPaths.emulator {
            let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
            guard let libraryDirectory = libraryDirectory.first else {
                return
            }
            fileURL = libraryDirectory + fileURL
        }
        let executableURL = URL(fileURLWithPath: fileURL)
        let task = Process()
        
        task.executableURL = executableURL
        task.arguments = arguments
        task.standardOutput = standardOutput
        
        try task.run()
    }
    
    func launchDevice(uuid: String) {
        do {
            try runProcess(processURL: ProcessPaths.xcrun, arguments: ["simctl", "boot", uuid])
        } catch {
            print(error)
        }
    }
    
    func launchDevice(name: String) {
        do {
            try runProcess(processURL: ProcessPaths.emulator, arguments: ["@\(name)"])
        } catch {
            print(error)
        }
    }
    
    func getDevices(deviceType: DeviceType, _ completion: @escaping (GetDevicesResult) -> Void) {
        let outputPipe = Pipe()
        
        switch deviceType {
        case .iOS:
            do {
                try runProcess(processURL: ProcessPaths.xcrun, arguments: ["xctrace", "list", "devices"], standardOutput: outputPipe)
            } catch {
                completion(.failure(error))
                return
            }
            
            let outputString = getStringOutput(outputPipe)
            
            let splitted = outputString.components(separatedBy: "\n")
            
            var devices: [Device] = []
            splitted.forEach { line in
                let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\)")
                if (!device.isEmpty) {
                    let firstDevice = device[0]
                    if (!firstDevice[3].isEmpty) {
                        devices.append(Device(
                            name: firstDevice[1],
                            version: firstDevice[3],
                            uuid: firstDevice[4]
                        ))
                    }
                }
            }
            
            completion(.success(devices))
            
        case .Android:
            do {
                try runProcess(processURL: ProcessPaths.emulator, arguments: ["-list-avds"], standardOutput: outputPipe)
            } catch {
                completion(.failure(error))
                return
            }
            
            let outputString = getStringOutput(outputPipe)
            
            let splitted = outputString.components(separatedBy: "\n")
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
