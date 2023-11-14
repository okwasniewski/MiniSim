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
    var pinned: Bool
    
    var displayName: String {
        let pinIcon = pinned ? " 📌" : ""
        switch platform {
        case .ios:
            if let version {
                return "\(name) - (\(version))" + pinIcon
            }
            return name + pinIcon
            
        case .android:
            return name + pinIcon
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case name, version, ID, booted, platform, displayName, pinned
    }
    
    init(name: String, version: String? = nil, ID: String?, booted: Bool = false, platform: Platform, pinned: Bool = false) {
        self.name = name
        self.version = version
        self.ID = ID
        self.booted = booted
        self.platform = platform
        self.pinned = pinned
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        version = try values.decode(String.self, forKey: .version)
        ID = try values.decode(String.self, forKey: .ID)
        booted = try values.decode(Bool.self, forKey: .booted)
        platform = try values.decode(Platform.self, forKey: .platform)
        pinned = try values.decode(Bool.self, forKey: .pinned)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(version, forKey: .version)
        try container.encode(ID, forKey: .ID)
        try container.encode(booted, forKey: .booted)
        try container.encode(platform, forKey: .platform)
        try container.encode(displayName, forKey: .displayName)
    }
}
