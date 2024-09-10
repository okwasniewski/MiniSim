//
//  LaunchDeviceCommand.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 09/07/2023.
//

import Cocoa
import Foundation

class LaunchDeviceCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let deviceName = self.property(forKey: "deviceName") as? String else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError
            return nil
        }

        do {
            var devices: [Device] = []
            try devices.append(contentsOf: DeviceServiceFactory.getDeviceDiscoveryService(platform: .ios).getDevices())
            try devices.append(contentsOf: DeviceServiceFactory.getDeviceDiscoveryService(platform: .android).getDevices())

            guard let device = devices.first(where: { $0.name == deviceName }) else {
                scriptErrorNumber = NSInternalScriptError
                return nil
            }

            if device.booted {
                device.focus()
                return nil
            }

            try? device.launch()
            return nil
        } catch {
            scriptErrorNumber = NSInternalScriptError
            return nil
        }
    }
}
