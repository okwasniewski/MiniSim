//
//  GetDevicesCommand.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 09/07/2023.
//

import Cocoa
import Foundation

class GetDevicesCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard
            let platformArg = self.property(forKey: "platform") as? String,
            let platform = Platform(rawValue: platformArg),
            let deviceTypeArg = self.property(forKey: "deviceType") as? String,
            let deviceType = DeviceType(rawValue: deviceTypeArg)
        else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError
            return nil
        }

        do {
            return try self.encode(DeviceServiceFactory.getDeviceDiscoveryService(platform: platform).getDevices(type: deviceType))
        } catch {
            scriptErrorNumber = NSInternalScriptError
            return nil
        }
    }
}
