//
//  Variables.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 02/06/2023.
//

import Foundation

enum Variables: String {
    case device_name = "$device_name"
    
    // Android Specific
    case adb_id = "$adb_id"
    case android_home_path = "$android_home_path"
    case adb_path = "$adb_path"
    
    // iOS Specific
    case uuid = "$uuid"
    case xcrun_path = "$xcrun_path"
    
    static var common: [Variables] {
        return [device_name]
    }
    
    static var android: [Variables] {
        return [android_home_path, adb_path]
    }
    
    static var ios: [Variables] {
        return [uuid, xcrun_path]
    }
    
    var description: String {
        switch self {
        case .device_name:
            return NSLocalizedString("Name of the device", comment: "")
        case .adb_id:
            return NSLocalizedString("ID of running device for example: emulator-5554", comment: "")
        case .android_home_path:
            return NSLocalizedString("Path of $ANDROID_HOME", comment: "")
        case .adb_path:
            return NSLocalizedString("Path of adb utility", comment: "")
        case .uuid:
            return NSLocalizedString("Unique identifier of iOS simulator", comment: "")
        case .xcrun_path:
            return NSLocalizedString("Path to xcrun utility", comment: "")
        }
    }
}
