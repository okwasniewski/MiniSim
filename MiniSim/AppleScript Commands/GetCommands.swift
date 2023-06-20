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
            return "Error: Unexpected argument passed"
        }
        
        do {
            var commands: [Command] = []
            switch platform {
            case .android:
                commands = AndroidSubMenuItem.allCases.map { item in
                    item.CommandItem
                }
            case .ios:
                commands = IOSSubMenuItem.allCases.map { item in
                    item.CommandItem
                }
            }
            
            let customCommands = DeviceService.getCustomCommands(platform: platform)
            commands.append(contentsOf: customCommands)
            
            return try self.encode(commands)
            
        } catch {
            return "Error: failed to get commands"
        }
        
    }
}
