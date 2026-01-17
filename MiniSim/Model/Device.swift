import Foundation

struct Device: Hashable, Codable {
  var name: String
  var version: String?
  var identifier: String?
  var booted: Bool
  var platform: Platform
  var type: DeviceType
  var deviceFamily: DeviceFamily?

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
    case name, version, identifier, booted, platform, displayName, type, deviceFamily
  }

  init(
    name: String,
    version: String? = nil,
    identifier: String?,
    booted: Bool = false,
    platform: Platform,
    type: DeviceType,
    deviceFamily: DeviceFamily? = nil
  ) {
    self.name = name
    self.version = version
    self.identifier = identifier
    self.booted = booted
    self.platform = platform
    self.type = type
    self.deviceFamily = deviceFamily
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    name = try values.decode(String.self, forKey: .name)
    version = try values.decode(String.self, forKey: .version)
    identifier = try values.decode(String.self, forKey: .identifier)
    booted = try values.decode(Bool.self, forKey: .booted)
    platform = try values.decode(Platform.self, forKey: .platform)
    type = try values.decode(DeviceType.self, forKey: .type)
    deviceFamily = try values.decodeIfPresent(DeviceFamily.self, forKey: .deviceFamily)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(version, forKey: .version)
    try container.encode(identifier, forKey: .identifier)
    try container.encode(booted, forKey: .booted)
    try container.encode(platform, forKey: .platform)
    try container.encode(displayName, forKey: .displayName)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(deviceFamily, forKey: .deviceFamily)
  }
}
