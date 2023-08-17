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
    
    enum CodingKeys: String, CodingKey {
        case name, version, ID, booted, platform, displayName
    }
    
    init(name: String, version: String? = nil, ID: String?, booted: Bool = false, platform: Platform) {
        self.name = name
        self.version = version
        self.ID = ID
        self.booted = booted
        self.platform = platform
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        version = try values.decode(String.self, forKey: .version)
        ID = try values.decode(String.self, forKey: .ID)
        booted = try values.decode(Bool.self, forKey: .booted)
        platform = try values.decode(Platform.self, forKey: .platform)
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
