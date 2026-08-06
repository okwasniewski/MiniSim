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
      arguments: ["simctl", "list", "devices", "available", "-j"]
    )
    return DeviceParserFactory().getParser(.iosSimulator).parse(output)
  }

  func checkSetup() throws -> Bool {
    FileManager.default.fileExists(atPath: DeviceConstants.ProcessPaths.xcrun.rawValue)
  }
}

final class HarmonyDeviceTool {
  private static let processLock = NSLock()
  private static var activeProcesses: [String: Process] = [:]

  static func getEmulatorPath(
    fileManager: FileManager = .default,
    homeDirectory: String = NSHomeDirectory()
  ) throws -> String {
    var candidates = [
      DeviceConstants.ProcessPaths.harmonyEmulator.rawValue,
      "\(homeDirectory)/Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator"
    ]

    for applicationsDirectory in ["/Applications", "\(homeDirectory)/Applications"] {
      let applicationPaths = (try? fileManager.contentsOfDirectory(atPath: applicationsDirectory)) ?? []
      candidates.append(contentsOf: applicationPaths
        .filter { $0.lowercased().hasPrefix("deveco-studio") && $0.hasSuffix(".app") }
        .map { "\(applicationsDirectory)/\($0)/Contents/tools/emulator/Emulator" })
    }

    guard let path = candidates.first(where: { fileManager.isExecutableFile(atPath: $0) }) else {
      throw DeviceError.harmonyStudioError
    }

    return path
  }

  /// The DevEco emulator is distributed as a bare executable. On recent macOS
  /// versions that executable can be terminated by TCC when it opens the host
  /// camera because it has no containing app bundle with a usage description.
  /// Build a private app bundle for the executable so MiniSim can still launch
  /// the emulator directly without opening DevEco Studio.
  static func getLaunchEmulatorPath(
    sourcePath: String,
    fileManager: FileManager = .default,
    homeDirectory: String = NSHomeDirectory()
  ) throws -> String {
    try HarmonyEmulatorBundle.executablePath(
      sourcePath: sourcePath,
      fileManager: fileManager,
      homeDirectory: homeDirectory
    )
  }

  static func launchArguments(for deviceName: String, additionalArgs: [String] = []) -> [String] {
    ["-start", deviceName, "-bootmode", "coldboot_no_save"] + additionalArgs
  }

  /// Starts DevEco's emulator as an independent process. The emulator remains
  /// alive after this method returns, so its later shutdown does not become a
  /// ShellOut error in MiniSim.
  static func launch(path: String, arguments: [String], deviceName: String) throws {
    processLock.lock()
    if activeProcesses[deviceName] != nil {
      processLock.unlock()
      return
    }

    let process = Process()
    activeProcesses[deviceName] = process
    processLock.unlock()

    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    process.terminationHandler = { _ in
      processLock.lock()
      activeProcesses.removeValue(forKey: deviceName)
      processLock.unlock()
    }

    do {
      try process.run()
    } catch {
      processLock.lock()
      activeProcesses.removeValue(forKey: deviceName)
      processLock.unlock()
      throw error
    }
  }
}

private enum HarmonyEmulatorBundle {
  private static let bundleName = "HarmonyEmulator.app"
  private static let bundleIdentifier = "com.oskarkwasniewski.MiniSim.HarmonyEmulator"

  static func executablePath(
    sourcePath: String,
    fileManager: FileManager = .default,
    homeDirectory: String = NSHomeDirectory()
  ) throws -> String {
    let applicationSupport = URL(fileURLWithPath: homeDirectory)
      .appendingPathComponent("Library/Application Support/MiniSim", isDirectory: true)
    let bundleURL = applicationSupport.appendingPathComponent(bundleName, isDirectory: true)
    let executableURL = bundleURL.appendingPathComponent("Contents/MacOS/Emulator")
    let sourceURL = URL(fileURLWithPath: sourcePath)

    guard fileManager.isExecutableFile(atPath: sourcePath) else {
      throw DeviceError.harmonyStudioError
    }

    if !isCurrentBundle(
      bundleURL: bundleURL,
      executableURL: executableURL,
      sourceURL: sourceURL,
      fileManager: fileManager
    ) {
      try installBundle(
        bundleURL: bundleURL,
        sourceURL: sourceURL,
        applicationSupport: applicationSupport,
        fileManager: fileManager
      )
    }

    guard fileManager.isExecutableFile(atPath: executableURL.path) else {
      throw DeviceError.harmonyStudioError
    }
    return executableURL.path
  }

  private static func infoDictionary() -> [String: String] {
    [
      "CFBundleDevelopmentRegion": "en",
      "CFBundleDisplayName": "MiniSim HarmonyOS Emulator",
      "CFBundleExecutable": "Emulator",
      "CFBundleIdentifier": bundleIdentifier,
      "CFBundleInfoDictionaryVersion": "6.0",
      "CFBundleName": "MiniSim HarmonyOS Emulator",
      "CFBundlePackageType": "APPL",
      "CFBundleShortVersionString": "1.0",
      "CFBundleVersion": "1",
      "LSMinimumSystemVersion": "12.0",
      "NSCameraUsageDescription": "MiniSim uses the camera to provide camera input to the HarmonyOS simulator.",
      "NSMicrophoneUsageDescription": "MiniSim uses the microphone to provide audio input to the HarmonyOS simulator."
    ]
  }

  private static func isCurrentBundle(
    bundleURL: URL,
    executableURL: URL,
    sourceURL: URL,
    fileManager: FileManager
  ) -> Bool {
    guard fileManager.isExecutableFile(atPath: executableURL.path) else { return false }

    let markerURL = bundleURL.appendingPathComponent("Contents/.minisim-source")
    guard let marker = try? String(contentsOf: markerURL, encoding: .utf8) else { return false }
    guard let sourceAttributes = try? fileManager.attributesOfItem(atPath: sourceURL.path),
          let sourceSize = sourceAttributes[.size] as? NSNumber,
          let sourceDate = sourceAttributes[.modificationDate] as? Date else {
      return false
    }

    let expectedMarker = "\(sourceURL.path)\n\(sourceSize.int64Value)\n\(sourceDate.timeIntervalSince1970)\n"
    return marker == expectedMarker
  }

  private static func installBundle(
    bundleURL: URL,
    sourceURL: URL,
    applicationSupport: URL,
    fileManager: FileManager
  ) throws {
    try fileManager.createDirectory(at: applicationSupport, withIntermediateDirectories: true)

    let temporaryBundle = applicationSupport
      .appendingPathComponent(".\(bundleName).\(UUID().uuidString)", isDirectory: true)
    let contentsURL = temporaryBundle.appendingPathComponent("Contents", isDirectory: true)
    let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)

    do {
      try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
      // Keep the original DevEco layout beside the executable. This preserves
      // Qt plugin lookup and the emulator's @loader_path run paths.
      let sourceDirectory = sourceURL.deletingLastPathComponent()
      let sourceItems = try fileManager.contentsOfDirectory(
        at: sourceDirectory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )
      for sourceItem in sourceItems {
        try fileManager.copyItem(
          at: sourceItem,
          to: macOSURL.appendingPathComponent(sourceItem.lastPathComponent)
        )
      }

      let plistURL = contentsURL.appendingPathComponent("Info.plist")
      let plistData = try PropertyListSerialization.data(
        fromPropertyList: infoDictionary(),
        format: .xml,
        options: 0
      )
      try plistData.write(to: plistURL, options: .atomic)

      let sourceAttributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
      let sourceSize = (sourceAttributes[.size] as? NSNumber)?.int64Value ?? 0
      let sourceDate = (sourceAttributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
      let marker = "\(sourceURL.path)\n\(sourceSize)\n\(sourceDate)\n"
      try marker.write(
        to: contentsURL.appendingPathComponent(".minisim-source"),
        atomically: true,
        encoding: .utf8
      )

      if fileManager.fileExists(atPath: bundleURL.path) {
        try fileManager.removeItem(at: bundleURL)
      }
      try fileManager.moveItem(at: temporaryBundle, to: bundleURL)
    } catch {
      try? fileManager.removeItem(at: temporaryBundle)
      throw error
    }
  }
}

final class HarmonyDeviceDiscovery: DeviceDiscoveryService {
  var shell: ShellProtocol = Shell()

  func getDevices(type: DeviceType? = nil) throws -> [Device] {
    guard type != .physical else { return [] }

    let emulatorPath = try HarmonyDeviceTool.getEmulatorPath()
    let output = try shell.execute(command: emulatorPath, arguments: ["-list", "-details"])
    return DeviceParserFactory().getParser(.harmonySimulator).parse(output)
  }

  func checkSetup() throws -> Bool {
    _ = try HarmonyDeviceTool.getEmulatorPath()
    return true
  }
}
