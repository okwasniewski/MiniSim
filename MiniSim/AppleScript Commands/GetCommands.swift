//
//  GetCommands.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 09/07/2023.
//

import Foundation
import Cocoa

class GetCommands: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard
            let argument = self.property(forKey: "platform") as? String,
            let platform = Platform(rawValue: argument)
        else {
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError;
            return nil;
        }
        
        do {
            var commands: [Command] = []
            switch platform {
            case .android:
                commands = AndroidSubMenuItem.allCases.compactMap { $0.CommandItem }
            case .ios:
                commands = IOSSubMenuItem.allCases.compactMap { $0.CommandItem }
            }
            
            let customCommandTag = platform == .android ? AndroidSubMenuItem.customCommand.rawValue : IOSSubMenuItem.customCommand.rawValue
            
            let customCommands = DeviceService.getCustomCommands(platform: platform).map({
                Command(id: $0.id, name: $0.name, command: $0.command, icon: $0.icon, platform: $0.platform, needBootedDevice: $0.needBootedDevice, bootsDevice: $0.bootsDevice, tag: customCommandTag)
            })
            
            commands.append(contentsOf: customCommands)
            
            return try self.encode(commands)
            
        } catch {
            scriptErrorNumber = NSInternalScriptError;
            return nil
        }
        
    }
}
