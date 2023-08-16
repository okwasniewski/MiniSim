//
//  ExecuteCommand.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 15/08/2023.
//

import Foundation
import Cocoa

class ExecuteCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard
            let platformArg = self.property(forKey: "platform") as? String,
            let platform = Platform(rawValue: platformArg),
            let tag = self.property(forKey: "commandTag") as? String,
            let commandName = self.property(forKey: "commandName") as? String,
            let deviceName = self.property(forKey: "deviceName") as? String,
            let deviceId = self.property(forKey: "deviceId") as? String
        else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError;
            return nil;
        }
        
        let device = Device(name: deviceName, ID: deviceId, platform: platform)
        let rawTag = Int(tag) ?? 0
        
        if platform == .android {
            if let menuItem = AndroidSubMenuItem(rawValue: rawTag) {
                DeviceService.handleAndroidAction(device: device, commandTag: menuItem, itemName: commandName)
            }
            
            return nil;
        }
        
        
        if let menuItem = IOSSubMenuItem(rawValue: rawTag) {
            DeviceService.handleiOSAction(device: device, commandTag: menuItem, itemName: commandName)
        }
        
        
        return nil;
    }
}
