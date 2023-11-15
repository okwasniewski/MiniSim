//
//  Command.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/05/2023.
//

import Foundation

struct Command: Identifiable, Codable, Hashable {
    var id = UUID()
    /**
     Name of the command shown in the menubar.
     */
    let name: String

    /**
     Actual command to execute for eg: `adb devices`.
     */
    let command: String

    /**
     SFSymbol name - shown in the menu bar.
     */
    let icon: String

    /**
     Platform on which command will be executed.
     */
    let platform: Platform

    /**
     Determines if command needs a booted device to execute.
     */
    var needBootedDevice: Bool

    /**
     Determines if command boots device.
     Needs to be optional to preserve backwards compatibility with data stored in UserDefaults.
     */
    var bootsDevice: Bool?

    /**
     Command tag used for AppleScript support.
     */
    var tag: Int?

    enum CodingKeys: CodingKey {
        case id
        case name
        case command
        case icon
        case platform
        case needBootedDevice
        case bootsDevice
        case tag
    }

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        icon: String,
        platform: Platform,
        needBootedDevice: Bool,
        bootsDevice: Bool? = nil,
        tag: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.icon = icon
        self.platform = platform
        self.needBootedDevice = needBootedDevice
        self.bootsDevice = bootsDevice
        self.tag = tag
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.command, forKey: .command)
        try container.encode(self.icon, forKey: .icon)
        try container.encode(self.platform, forKey: .platform)
        try container.encode(self.needBootedDevice, forKey: .needBootedDevice)
        try container.encodeIfPresent(self.bootsDevice, forKey: .bootsDevice)
        try container.encodeIfPresent(self.tag, forKey: .tag)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.command = try container.decode(String.self, forKey: .command)
        self.icon = try container.decode(String.self, forKey: .icon)

        // Support old way of storing data to preserve backward compatibility.
        if let oldPlatform = try? container.decode(OldPlatformType.self, forKey: .platform) {
            self.platform = oldPlatform == .android ? Platform.android : Platform.ios
        } else {
            self.platform = try container.decode(Platform.self, forKey: .platform)
        }

        self.needBootedDevice = try container.decode(Bool.self, forKey: .needBootedDevice)
        self.bootsDevice = try container.decodeIfPresent(Bool.self, forKey: .bootsDevice)
        self.tag = try container.decodeIfPresent(Int.self, forKey: .tag)
    }
}
