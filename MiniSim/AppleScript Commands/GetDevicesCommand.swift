//
//  GetDevicesCommand.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 09/07/2023.
//

import Foundation
import Cocoa

class GetDevicesCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard
            let argument = self.property(forKey: "platform") as? String,
            let platform = Platform(rawValue: argument)
        else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError
            return nil
        }

        do {
            if platform == .android {
                return try self.encode(DeviceService.getAndroidDevices())
            } else {
                return try self.encode(DeviceService.getIOSDevices())
            }

        } catch {
            scriptErrorNumber = NSInternalScriptError
            return nil
        }
    }
}
