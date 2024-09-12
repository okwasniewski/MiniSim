import Foundation

protocol DeviceDiscoveryService {
  var shell: ShellProtocol { get set }

  func getDevices(type: DeviceType?) throws -> [Device]
  func getDevices() throws -> [Device]
  func checkSetup() throws -> Bool
}

extension DeviceDiscoveryService {
  func getDevices() throws -> [Device] {
    try getDevices(type: nil)
  }
}

class AndroidDeviceDiscovery: DeviceDiscoveryService {
  var shell: ShellProtocol = Shell()

  func getDevices(type: DeviceType? = nil) throws -> [Device] {
    switch type {
    case .physical:
      return try getAndroidPhysicalDevices()
    case .virtual:
      return try getAndroidEmulators()
    case nil:
      let emulators = try getAndroidEmulators()
      let devices = try getAndroidPhysicalDevices()
      return emulators + devices
    }
  }

  private func getAndroidPhysicalDevices() throws -> [Device] {
    let adbPath = try ADB.getAdbPath()
    let output = try shell.execute(command: adbPath, arguments: ["devices", "-l"])

    return DeviceParserFactory().getParser(.androidPhysical).parse(output)
  }

  private func getAndroidEmulators() throws -> [Device] {
    let emulatorPath = try ADB.getEmulatorPath()
    let output = try shell.execute(command: emulatorPath, arguments: ["-list-avds"])

    return DeviceParserFactory().getParser(.androidEmulator).parse(output)
  }

  func checkSetup() throws -> Bool {
    let emulatorPath = try ADB.getAndroidHome()
    try ADB.checkAndroidHome(path: emulatorPath)
    return true
  }
}

class IOSDeviceDiscovery: DeviceDiscoveryService {
  var shell: ShellProtocol = Shell()

  func getDevices(type: DeviceType? = nil) throws -> [Device] {
    switch type {
    case .physical:
      return try getIOSPhysicalDevices()
    case .virtual:
      return try getIOSSimulators()
    case nil:
      let simulators = try getIOSSimulators()
      let devices = try getIOSPhysicalDevices()
      return simulators + devices
    }
  }

  func getIOSPhysicalDevices() throws -> [Device] {
    let tempDirectory = FileManager.default.temporaryDirectory
    let outputFile = tempDirectory.appendingPathComponent("iosPhysicalDevices.json")

    guard (try? shell.execute(
      command: DeviceConstants.ProcessPaths.xcrun.rawValue,
      arguments: ["devicectl", "list", "devices", "-j \(outputFile.path)"]
    )) != nil else {
      return []
    }

    let jsonString = try String(contentsOf: outputFile)
    return DeviceParserFactory().getParser(.iosPhysical).parse(jsonString)
  }

  func getIOSSimulators() throws -> [Device] {
    let output = try shell.execute(
      command: DeviceConstants.ProcessPaths.xcrun.rawValue,
      arguments: ["simctl", "list", "devices", "available"]
    )
    return DeviceParserFactory().getParser(.iosSimulator).parse(output)
  }

  func checkSetup() throws -> Bool {
    FileManager.default.fileExists(atPath: DeviceConstants.ProcessPaths.xcrun.rawValue)
  }
}
