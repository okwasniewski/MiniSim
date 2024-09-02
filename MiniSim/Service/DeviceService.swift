//
//  DeviceService.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import AppKit
import Foundation
import ShellOut
import UserNotifications

protocol DeviceServiceProtocol {
  static func getIOSDevices() throws -> [Device]
  static func checkXcodeSetup() -> Bool
  static func deleteSimulator(uuid: String) throws

  static func toggleA11y(device: Device) throws
  static func getAndroidDevices() throws -> [Device]
  static func sendText(device: Device, text: String) throws
  static func checkAndroidSetup() throws -> String

  static func focusDevice(_ device: Device)
  static func runCustomCommand(_ device: Device, command: Command) throws
  static func getCustomCommands(platform: Platform) -> [Command]
  static func getCustomCommand(platform: Platform, commandName: String) -> Command?
  static func showSuccessMessage(title: String, message: String)
}

class DeviceService: DeviceServiceProtocol {
  private static let queue = DispatchQueue(
    label: "com.MiniSim.DeviceService",
    qos: .userInteractive,
    attributes: .concurrent
  )
  private static let deviceBootedError = "Unable to boot device in current state: Booted"
  private static let derivedDataLocation = "~/Library/Developer/Xcode/DerivedData"

  private enum ProcessPaths: String {
    case xcrun = "/usr/bin/xcrun"
    case xcodeSelect = "/usr/bin/xcode-select"
    case systemProfiler = "/usr/sbin/system_profiler"
  }

  private enum BundleURL: String {
    case emulator = "qemu-system-aarch64"
    case simulator = "Simulator.app"
  }

  static func getCustomCommands(platform: Platform) -> [Command] {
    guard let commandsData = UserDefaults.standard.commands else { return [] }
    guard let commands = try? JSONDecoder().decode([Command].self, from: commandsData) else {
      return []
    }

    return commands.filter { $0.platform == platform }
  }

  static func getCustomCommand(platform: Platform, commandName: String) -> Command? {
    let commands = getCustomCommands(platform: platform)
    return commands.first { $0.name == commandName }
  }

  static func runCustomCommand(_ device: Device, command: Command) throws {
    Thread.assertBackgroundThread()
    var commandToExecute = command.command
      .replacingOccurrences(of: Variables.deviceName.rawValue, with: device.name)

    let deviceID = device.identifier ?? ""

    if command.platform == .android {
      commandToExecute = try commandToExecute
        .replacingOccurrences(of: Variables.adbPath.rawValue, with: ADB.getAdbPath())
        .replacingOccurrences(of: Variables.adbId.rawValue, with: deviceID)
        .replacingOccurrences(of: Variables.androidHomePath.rawValue, with: ADB.getAndroidHome())
    } else {
      commandToExecute = commandToExecute
        .replacingOccurrences(of: Variables.uuid.rawValue, with: deviceID)
        .replacingOccurrences(of: Variables.xcrunPath.rawValue, with: ProcessPaths.xcrun.rawValue)
    }

    do {
      try shellOut(to: commandToExecute)
      if command.bootsDevice ?? false && command.platform == .ios {
        try? launchSimulatorApp(uuid: deviceID)
      }
      NotificationCenter.default.post(name: .commandDidSucceed, object: nil)
    } catch {
      throw CustomCommandError.commandError(errorMessage: error.localizedDescription)
    }
  }

  static func focusDevice(_ device: Device) {
    queue.async {
      let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }

      if let uuid = device.identifier, device.platform == .ios {
        try? Self.launchSimulatorApp(uuid: uuid)
      }

      for app in runningApps {
        guard
          let bundleURL = app.bundleURL?.absoluteString,
          bundleURL.contains(BundleURL.simulator.rawValue) ||
            bundleURL.contains(BundleURL.emulator.rawValue) else {
          continue
        }
        let isAndroid = bundleURL.contains(BundleURL.emulator.rawValue)

        for window in AccessibilityElement.allWindowsForPID(app.processIdentifier) {
          guard let windowTitle = window.attribute(key: .title, type: String.self),
                !windowTitle.isEmpty else {
            continue
          }

          if !Self.matchDeviceTitle(windowTitle: windowTitle, device: device) {
            continue
          }

          if isAndroid {
            AccessibilityElement.forceFocus(pid: app.processIdentifier)
          } else {
            window.performAction(key: kAXRaiseAction)
            app.activate(options: [.activateIgnoringOtherApps])
          }
        }
      }
    }
  }

  private static func matchDeviceTitle(windowTitle: String, device: Device) -> Bool {
    if device.platform == .android {
      let deviceName = windowTitle.match(#"(?<=- ).*?(?=:)"#).first?.first
      return deviceName == device.name
    }

    let deviceName = windowTitle.match(#"^[^–]*"#).first?.first?.trimmingCharacters(in: .whitespacesAndNewlines)

    return deviceName == device.name
  }

  static func checkXcodeSetup() -> Bool {
    FileManager.default.fileExists(atPath: ProcessPaths.xcrun.rawValue)
  }

  static func checkAndroidSetup() throws -> String {
    let emulatorPath = try ADB.getAndroidHome()
    try ADB.checkAndroidHome(path: emulatorPath)
    return emulatorPath
  }

  static func showSuccessMessage(title: String, message: String) {
    UNUserNotificationCenter.showNotification(title: title, body: message)
    NotificationCenter.default.post(name: .commandDidSucceed, object: nil)
  }

  static func getAllDevices(
    android: Bool,
    iOS: Bool,
    completionQueue: DispatchQueue = .main,
    completion: @escaping ([Device], Error?) -> Void
  ) {
    queue.async {
      do {
        var devicesArray: [Device] = []

        if android {
          try devicesArray.append(contentsOf: getAndroidDevices())
        }

        if iOS {
          try devicesArray.append(contentsOf: getIOSDevices())
        }

        completionQueue.async {
          completion(devicesArray, nil)
        }
      } catch {
        completionQueue.async {
          completion([], error)
        }
      }
    }
  }

  private static func launch(device: Device) throws {
    Thread.assertBackgroundThread()
    switch device.platform {
    case .ios:
      try launchDevice(uuid: device.identifier ?? "")
    case .android:
      try launchDevice(name: device.name)
    }
  }

  static func launch(device: Device, completionQueue: DispatchQueue = .main, completion: @escaping (Error?) -> Void) {
    self.queue.async {
      do {
        try self.launch(device: device)
        completionQueue.async {
          completion(nil)
        }
      } catch {
        if error.localizedDescription.contains(deviceBootedError) {
          return
        }
        completionQueue.async {
          completion(error)
        }
      }
    }
  }
}

// MARK: iOS Methods
extension DeviceService {
  private static func parseIOSPhysicalDevices(result: [String]) -> [Device] {
    var devices = [Device]()

    let deviceNameIdx = 1
    let osVersionIdx = 2
    let identifierIdx = 3
    var isDevice = false
    var isOnline = true
    for line in result {
      if let match = line.match("== ([\\s\\w]+) ==").first {
        isDevice = match[1].contains("Devices")
        isOnline = !match[1].contains("Offline")
        continue
      }

      guard isDevice else { continue }

      // The version is set as optional which only is the case for the device running
      // the application, for example your MacBook, maybe we can make it not optional
      // because we filter that device anyway but just in case some other device also has this behavior
      guard let match = line.match("(.+?)\\s(?:\\(([\\d\\.]+)\\))?\\s?\\((\\S+)\\)").first else {
        continue
      }

      let deviceName = match[deviceNameIdx]
      let osVersion = match[osVersionIdx]
      let identifier = match[identifierIdx]

      devices.append(
        Device(
          name: deviceName,
          version: osVersion.isEmpty ? nil : osVersion,
          identifier: identifier,
          booted: isOnline,
          platform: .ios,
          type: .physical
        )
      )
    }

    return devices
  }

  static func clearDerivedData(
    completionQueue: DispatchQueue = .main,
    completion: @escaping (String, Error?) -> Void
  ) {
    self.queue.async {
      do {
        let amountCleared = try? shellOut(to: "du -sh \(derivedDataLocation)")
          .match(###"\d+\.?\d+\w+"###).first?.first
        try shellOut(to: "rm -rf \(derivedDataLocation)")
        completionQueue.async {
          completion(amountCleared ?? "", nil)
        }
      } catch {
        completionQueue.async {
          completion("", error)
        }
      }
    }
  }

  static func getIOSDevices() throws -> [Device] {
    Thread.assertBackgroundThread()
    let simulators = try getIOSSimulators()
    let devices = try getIOSPhysicalDevices()
    return simulators + devices
  }

  static var currentMachineUUID: String? {
    guard let output = try? shellOut(
      to: ProcessPaths.systemProfiler.rawValue,
      arguments: ["SPHardwareDataType"]
    ) else { return nil }

    let uuidIdx = 1
    for line in output.components(separatedBy: "\n") {
      guard let match = line.match("Hardware UUID: ([\\S]+)").first else {
        continue
      }

      if match.count >= 2 {
        return match[uuidIdx]
      }
    }

    return nil
  }

  static func getIOSPhysicalDevices() throws -> [Device] {
    let tempDirectory = FileManager.default.temporaryDirectory
    let outputFile = tempDirectory.appendingPathComponent("iosPhysicalDevices.json")

    try shellOut(
      to: ProcessPaths.xcrun.rawValue,
      arguments: ["devicectl", "list", "devices", "-j \(outputFile.path)"]
    )

    let jsonString = try String(contentsOf: outputFile)
    return DeviceParserFactory().getParser(.iosPhysical).parse(jsonString)
  }

  static func getIOSSimulators() throws -> [Device] {
    let output = try shellOut(
      to: ProcessPaths.xcrun.rawValue,
      arguments: ["simctl", "list", "devices", "available"]
    )
    return DeviceParserFactory().getParser(.iosSimulator).parse(output)
  }

  static func launchSimulatorApp(uuid: String) throws {
    let isSimulatorRunning = NSWorkspace.shared.runningApplications
      .contains { $0.bundleIdentifier == "com.apple.iphonesimulator" }

    if !isSimulatorRunning {
      guard let activeDeveloperDir = try? shellOut(
        to: ProcessPaths.xcodeSelect.rawValue,
        arguments: ["-p"]
      )
        .trimmingCharacters(in: .whitespacesAndNewlines) else {
        throw DeviceError.xcodeError
      }
      try shellOut(
        to: "\(activeDeveloperDir)/Applications/Simulator.app/Contents/MacOS/Simulator",
        arguments: ["--args", "-CurrentDeviceUDID", uuid]
      )
    }
  }

  private static func launchDevice(uuid: String) throws {
    do {
      try self.launchSimulatorApp(uuid: uuid)
      try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "boot", uuid])
    } catch {
      if !error.localizedDescription.contains(deviceBootedError) {
        throw error
      }
    }
  }

  static func deleteSimulator(uuid: String) throws {
    Thread.assertBackgroundThread()
    try shellOut(to: ProcessPaths.xcrun.rawValue, arguments: ["simctl", "delete", uuid])
  }

  static func handleiOSAction(device: Device, commandTag: SubMenuItems.Tags, itemName: String) {
    queue.async {
      switch commandTag {
      case .copyName:
        NSPasteboard.general.copyToPasteboard(text: device.name)
        DeviceService.showSuccessMessage(title: "Device name copied to clipboard!", message: device.name)
      case .copyID:
        if let deviceID = device.identifier {
          NSPasteboard.general.copyToPasteboard(text: deviceID)
          DeviceService.showSuccessMessage(title: "Device ID copied to clipboard!", message: deviceID)
        }
      case .delete:
        DispatchQueue.main.async {
          guard let deviceID = device.identifier else { return }
          let result = !NSAlert.showQuestionDialog(
            title: "Are you sure?",
            message: "Are you sure you want to delete this Simulator?"
          )
          if result { return }

          queue.async {
            do {
              try DeviceService.deleteSimulator(uuid: deviceID)
              DeviceService.showSuccessMessage(title: "Simulator deleted!", message: deviceID)
              NotificationCenter.default.post(name: .deviceDeleted, object: nil)
            } catch {
              NSAlert.showError(message: error.localizedDescription)
            }
          }
        }
      case .customCommand:
        guard let command = DeviceService.getCustomCommand(platform: .ios, commandName: itemName) else {
          return
        }

        do {
          try DeviceService.runCustomCommand(device, command: command)
        } catch {
          NSAlert.showError(message: error.localizedDescription)
        }
      default:
        break
      }
    }
  }
}

// MARK: Android Methods
extension DeviceService {
  private static func launchDevice(name: String, additionalArguments: [String] = []) throws {
    Thread.assertBackgroundThread()
    let emulatorPath = try ADB.getEmulatorPath()
    var arguments = ["@\(name)"]
    let formattedArguments = additionalArguments
      .filter { !$0.isEmpty }
      .map { $0.hasPrefix("-") ? $0 : "-\($0)" }
    arguments.append(contentsOf: getAndroidLaunchParams())
    arguments.append(contentsOf: formattedArguments)
    do {
      try shellOut(to: emulatorPath, arguments: arguments)
    } catch {
      // Ignore force qutting emulator (CMD + Q)
      if error.localizedDescription.contains("unexpected system image feature string") {
        return
      }
      throw error
    }
  }

  private static func getAndroidLaunchParams() -> [String] {
    guard let paramData = UserDefaults.standard.parameters else { return [] }
    guard let parameters = try? JSONDecoder().decode([Parameter].self, from: paramData) else {
      return []
    }

    return parameters.filter { $0.enabled }
      .map { $0.command }
  }

  static func getAndroidDevices() throws -> [Device] {
    Thread.assertBackgroundThread()
    let emulators = try getAndroidEmulators()
    let devices = try getAndroidPhysicalDevices()
    return emulators + devices
  }

  static func getAndroidPhysicalDevices() throws -> [Device] {
      let adbPath = try ADB.getAdbPath()
      let output = try shellOut(to: adbPath, arguments: ["devices", "-l"])

    return DeviceParserFactory().getParser(.androidPhysical).parse(output)
  }

  static func getAndroidEmulators() throws -> [Device] {
    let emulatorPath = try ADB.getEmulatorPath()
    let output = try shellOut(to: emulatorPath, arguments: ["-list-avds"])

    return DeviceParserFactory().getParser(.androidEmulator).parse(output)
  }

  static func toggleA11y(device: Device) throws {
    Thread.assertBackgroundThread()

    let adbPath = try ADB.getAdbPath()
    guard let adbId = device.identifier else {
      throw DeviceError.deviceNotFound
    }

    let a11yIsEnabled = ADB.isAccesibilityOn(deviceId: adbId, adbPath: adbPath)
    let value = a11yIsEnabled ? ADB.talkbackOff : ADB.talkbackOn
    let shellCmd = "\(adbPath) -s \(adbId) shell settings put secure enabled_accessibility_services \(value)"
    _ = try? shellOut(to: shellCmd)
  }

  static func sendText(device: Device, text: String) throws {
    Thread.assertBackgroundThread()
    let adbPath = try ADB.getAdbPath()
    guard let deviceId = device.identifier else {
      throw DeviceError.deviceNotFound
    }

    let formattedText = text.replacingOccurrences(of: " ", with: "%s").replacingOccurrences(of: "'", with: "''")

    try shellOut(to: "\(adbPath) -s \(deviceId) shell input text \"\(formattedText)\"")
  }

  static func deleteEmulator(device: Device) throws {
    Thread.assertBackgroundThread()
    let avdPath = try ADB.getAvdPath()
    let adbPath = try ADB.getAdbPath()
    if device.booted {
      guard let deviceId = device.identifier else {
        throw DeviceError.deviceNotFound
      }
      try shellOut(to: "\(adbPath) -s \(deviceId) emu kill")
    }
    try shellOut(to: "\(avdPath) delete avd -n \"\(device.name)\"")
  }

  static func launchLogCat(device: Device) throws {
    Thread.assertBackgroundThread()
    guard let deviceId = device.identifier else {
      throw DeviceError.deviceNotFound
    }

    guard let adbPath = try? ADB.getAdbPath() else { return }
    let logcatCommand = "\(adbPath) -s \(deviceId) logcat -v color"
    try TerminalService.launchTerminal(command: logcatCommand)
  }

  static func handleAndroidAction(device: Device, commandTag: SubMenuItems.Tags, itemName: String) {
    queue.async {
      do {
        switch commandTag {
        case .coldBoot:
          try DeviceService.launchDevice(name: device.name, additionalArguments: ["-no-snapshot"])

        case .noAudio:
          try DeviceService.launchDevice(name: device.name, additionalArguments: ["-no-audio"])

        case .toggleA11y:
          try DeviceService.toggleA11y(device: device)

        case .copyID:
          if let deviceId = device.identifier {
            NSPasteboard.general.copyToPasteboard(text: deviceId)
            DeviceService.showSuccessMessage(title: "Device ID copied to clipboard!", message: deviceId)
          }

        case .copyName:
          NSPasteboard.general.copyToPasteboard(text: device.name)
          DeviceService.showSuccessMessage(title: "Device name copied to clipboard!", message: device.name)

        case .paste:
          guard let clipboard = NSPasteboard.general.pasteboardItems?.first,
                let text = clipboard.string(forType: .string) else {
            break
          }
          try DeviceService.sendText(device: device, text: text)

        case .customCommand:
          if let command = DeviceService.getCustomCommand(platform: .android, commandName: itemName) {
            try DeviceService.runCustomCommand(device, command: command)
          }
        case .logcat:
          try DeviceService.launchLogCat(device: device)

        case .delete:
          DispatchQueue.main.async {
            let result = !NSAlert.showQuestionDialog(
              title: "Are you sure?",
              message: "Are you sure you want to delete this Emulator?"
            )
            if result { return }
            queue.async {
              do {
                try DeviceService.deleteEmulator(device: device)
                DeviceService.showSuccessMessage(title: "Emulator deleted!", message: device.name)
                NotificationCenter.default.post(name: .deviceDeleted, object: nil)
              } catch {
                NSAlert.showError(message: error.localizedDescription)
              }
            }
          }
        }
      } catch {
        NSAlert.showError(message: error.localizedDescription)
      }
    }
  }
}
