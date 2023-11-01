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
            let argument = self.property(forKey: "platform") as? String,
            let platform = Platform(rawValue: argument)
        else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError
            return nil
        }

        do {
            switch platform {
            case .android:
                return try self.encode(DeviceService.getAndroidDevices())
            case .ios:
                return try self.encode(DeviceService.getIOSDevices())
            }
        } catch {
            scriptErrorNumber = NSInternalScriptError
            return nil
        }
    }
}
