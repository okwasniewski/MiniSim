//
//  LaunchDeviceCommand.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 09/07/2023.
//

import Foundation
import Cocoa

class LaunchDeviceCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let deviceName = self.property(forKey: "deviceName") as? String else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError;
            return nil;
        }
        
        do {
            var devices: [Device] = []
            try devices.append(contentsOf: DeviceService.getIOSDevices())
            try devices.append(contentsOf: DeviceService.getAndroidDevices())
            
            guard let device = devices.first(where: { $0.name == deviceName }) else {
                scriptErrorNumber = NSInternalScriptError;
                return nil
            }
            
            if device.booted {
                Task {
                    await DeviceService.focusDevice(device)
                }
                return nil
            }
            
            Task {
                try? await DeviceService.launch(device: device)
            }
            return nil
        } catch {
            scriptErrorNumber = NSInternalScriptError;
            return nil
        }
    }
}
