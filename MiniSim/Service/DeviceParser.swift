import Foundation

enum DeviceParserType {
  case iosSimulator
  case iosPhysical
  case androidEmulator
  case androidPhysical
}

protocol DeviceParser {
  func parse(_ input: String) -> [Device]
}

class DeviceParserFactory {
  func getParser(_ type: DeviceParserType) -> DeviceParser {
    switch type {
    case .iosSimulator:
      return IOSSimulatorParser()
    case .iosPhysical:
      return IOSPhysicalDeviceParser()
    case .androidEmulator:
      return AndroidEmulatorParser()
    case .androidPhysical:
      return AndroidPhysicalDeviceParser()
    }
  }
}

class IOSSimulatorParser: DeviceParser {
  struct SimulatorDevice: Codable {
    let name: String
    let udid: String
    let state: String
    let deviceTypeIdentifier: String
    let isAvailable: Bool
  }

  struct SimctlOutput: Codable {
    let devices: [String: [SimulatorDevice]]
  }

  func parse(_ input: String) -> [Device] {
    guard let jsonData = input.data(using: .utf8) else { return [] }
    guard let simctlOutput = try? JSONDecoder().decode(SimctlOutput.self, from: jsonData) else {
      return []
    }

    var devices: [Device] = []

    for (runtimeIdentifier, simulatorDevices) in simctlOutput.devices {
      let osVersion = parseOSVersion(from: runtimeIdentifier)

      for simulator in simulatorDevices {
        let deviceFamily = DeviceFamily(fromDeviceTypeIdentifier: simulator.deviceTypeIdentifier)

        devices.append(
          Device(
            name: simulator.name,
            version: osVersion,
            identifier: simulator.udid,
            booted: simulator.state == "Booted",
            platform: .ios,
            type: .virtual,
            deviceFamily: deviceFamily
          )
        )
      }
    }

    return devices
  }

  /// Parses OS version from runtime identifier.
  /// Example: `com.apple.CoreSimulator.SimRuntime.iOS-18-5` -> `iOS 18.5`
  private func parseOSVersion(from runtimeIdentifier: String) -> String {
    let pattern = "com\\.apple\\.CoreSimulator\\.SimRuntime\\.(\\w+)-(\\d+)-(\\d+)"
    guard let match = runtimeIdentifier.match(pattern).first, match.count >= 4 else {
      return runtimeIdentifier
    }
    let platform = match[1]
    let major = match[2]
    let minor = match[3]
    return "\(platform) \(major).\(minor)"
  }
}

class IOSPhysicalDeviceParser: DeviceParser {
  struct IOSPhysicalDevicesJson: Codable {
    struct Info: Codable {
      var outcome: String
    }

    struct DeviceProperties: Codable {
      let name: String
      let osVersionNumber: String
    }

    struct HardwareProperties: Codable {
      let udid: String
    }

    struct ConnectionProperties: Codable {
      let tunnelState: String
    }

    struct Device: Codable {
      let deviceProperties: DeviceProperties
      let hardwareProperties: HardwareProperties
      let connectionProperties: ConnectionProperties
    }

    struct Result: Codable {
      let devices: [Device]
    }

    let info: Info
    let result: Result
  }

  func parse(_ input: String) -> [Device] {
    guard let jsonData = input.data(using: .utf8) else { return [] }
    guard let jsonObject = try? JSONDecoder().decode(IOSPhysicalDevicesJson.self, from: jsonData) else { return [] }

    guard jsonObject.info.outcome == "success" else { return [] }
    return jsonObject.result.devices.map { jsonObjectDevice in
      Device(
        name: jsonObjectDevice.deviceProperties.name,
        version: jsonObjectDevice.deviceProperties.osVersionNumber,
        identifier: jsonObjectDevice.hardwareProperties.udid,
        booted: !["unavailable", "disconnected"].contains(jsonObjectDevice.connectionProperties.tunnelState),
        platform: .ios,
        type: .physical
      )
    }
  }
}

class AndroidEmulatorParser: DeviceParser {
  let adb: ADBProtocol.Type

  required init(adb: ADBProtocol.Type = ADB.self) {
    self.adb = adb
  }

  func parse(_ input: String) -> [Device] {
    let deviceNames = input.components(separatedBy: .newlines)
    return deviceNames
      .filter { !$0.isEmpty && !$0.contains("Storing crashdata") }
      .compactMap { deviceName in
        let adbId = try? adb.getAdbId(for: deviceName)
        return Device(name: deviceName, identifier: adbId, booted: adbId != nil, platform: .android, type: .virtual)
      }
  }
}

class AndroidPhysicalDeviceParser: DeviceParser {
  func parse(_ input: String) -> [Device] {
    var splitted = input.components(separatedBy: "\n")
    splitted.removeFirst() // removes 'List of devices attached'
    let filtered = splitted.filter { !$0.contains("emulator") }

    return filtered.compactMap { item -> Device? in
      let serialNoIdx = 0
      let modelNameIdx = 4
      let components = item.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
      guard components.count > 4  else {
        return nil
      }

      let id = components[serialNoIdx]
      let name = components[modelNameIdx].components(separatedBy: ":")[1]

      return Device(
        name: name,
        identifier: id,
        booted: true,
        platform: .android,
        type: .physical
      )
    }
}
}
