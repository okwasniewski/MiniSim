import Foundation

enum DeviceParserType {
  case iosSimulator
  case iosPhysical
  case androidEmulator
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
    }
  }
}

class IOSSimulatorParser: DeviceParser {
  func parse(_ input: String) -> [Device] {
    let lines = input.components(separatedBy: .newlines)
    var devices: [Device] = []
    let currentOSIdx = 1
    let deviceNameIdx = 1
    let identifierIdx = 4
    let deviceStateIdx = 5
    var osVersion = ""

    lines.forEach { line in
      if let currentOs = line.match("-- (.*?) --").first, !currentOs.isEmpty {
        osVersion = currentOs[currentOSIdx]
      }
      if let device = line.match("(.*?) (\\(([0-9.]+)\\) )?\\(([0-9A-F-]+)\\) (\\(.*?)\\)").first {
        devices.append(
          Device(
            name: device[deviceNameIdx].trimmingCharacters(in: .whitespacesAndNewlines),
            version: osVersion,
            identifier: device[identifierIdx],
            booted: device[deviceStateIdx].contains("Booted"),
            platform: .ios,
            type: .virtual
          )
        )
      }
    }
    return devices
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
        booted: jsonObjectDevice.connectionProperties.tunnelState != "unavailable",
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
    guard let adbPath = try? adb.getAdbPath() else { return [] }
    let deviceNames = input.components(separatedBy: .newlines)
    return deviceNames
      .filter { !$0.isEmpty && !$0.contains("Storing crashdata") }
      .compactMap { deviceName in
        let adbId = try? adb.getAdbId(for: deviceName, adbPath: adbPath)
        return Device(name: deviceName, identifier: adbId, booted: adbId != nil, platform: .android, type: .virtual)
      }
  }
}
