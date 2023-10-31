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
            scriptErrorNumber = NSRequiredArgumentsMissingScriptError
            return nil
        }

        let commands = platform.subMenuItems
            .compactMap { $0 as? SubMenuActionItem }
            .map { $0.commandItem }
        let customCommands = DeviceService.getCustomCommands(platform: platform)
            .map { command in
                Command(
                    id: command.id,
                    name: command.name,
                    command: command.command,
                    icon: command.icon,
                    platform: command.platform,
                    needBootedDevice: command.needBootedDevice,
                    bootsDevice: command.bootsDevice,
                    tag: SubMenuItems.Tags.customCommand.rawValue
                )
            }

        do {
            return try self.encode(commands + customCommands)
        } catch {
            scriptErrorNumber = NSInternalScriptError
            return nil
        }
    }
}

extension SubMenuActionItem {
    var commandItem: Command {
        Command(
            name: self.title,
            command: "",
            icon: "",
            platform: Platform.android,
            needBootedDevice: needBootedDevice,
            bootsDevice: self.bootsDevice,
            tag: self.tag
        )
    }
}
