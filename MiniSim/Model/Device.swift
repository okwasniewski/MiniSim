//
//  Device.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 25/01/2023.
//

struct Device: Hashable, Codable {
    var name: String
    var version: String?
    var ID: String?
    var booted: Bool = false
    var platform: Platform
    
    var displayName: String {
        switch platform {
        case .ios:
            if let version {
                return "\(name) - (\(version))"
            }
            return name
            
        case .android:
            return name
        }
    }
}
