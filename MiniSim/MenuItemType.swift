//
//  MenuItemType.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 27/01/2023.
//

import Cocoa

enum MenuItemType: Int {
    // Global
    case quit = 100
    case preferences = 101
    
    // Android
    case launchAndroid = 200
    
    // iOS
    case launchIOS = 300
}
