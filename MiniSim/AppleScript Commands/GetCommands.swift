//
//  GetCommands.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 09/07/2023.
//

import Cocoa
import Foundation

class GetCommands: NSScriptCommand {
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

        let commands = SubMenuItems.items(platform: platform, deviceType: deviceType)
            .compactMap { $0 as? SubMenuActionItem }
            .map { $0.commandItem }
        let customCommands = CustomCommandService.getCustomCommands(platform: platform)
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
