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
}
