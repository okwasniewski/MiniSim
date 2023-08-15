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
                commands = AndroidSubMenuItem.allCases.compactMap { item in
                    item.CommandItem
                }
            case .ios:
                commands = IOSSubMenuItem.allCases.compactMap { item in
                    item.CommandItem
                }
            }
            
//            let customCommands = DeviceService.getCustomCommands(platform: platform)
//            commands.append(contentsOf: customCommands)
            
            return try self.encode(commands)
            
        } catch {
            scriptErrorNumber = NSInternalScriptError;
            return nil
        }
        
    }
}
