import Foundation

enum DeviceParserType {
  case iosSimulator
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
            platform: .ios
          )
        )
      }
    }
    return devices
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
        return Device(name: deviceName, identifier: adbId, booted: adbId != nil, platform: .android)
      }
  }
}
