import AppKit
import Foundation

class AndroidDeviceService: DeviceServiceCommon {
  var shell: ShellProtocol = Shell()
  var device: Device

  init(device: Device) {
    self.device = device
  }

  func deleteDevice() throws {
    Thread.assertBackgroundThread()
    let avdPath = try ADB.getAvdPath()
    let adbPath = try ADB.getAdbPath()
    if device.booted {
      guard let deviceId = device.identifier else {
        throw DeviceError.deviceNotFound
      }
      try shell.execute(command: "\(adbPath) -s \(deviceId) emu kill")
    }
    try shell.execute(command: "\(avdPath) delete avd -n \"\(device.name)\"")
  }

  func launchDevice(additionalArgs: [String] = []) throws {
    Thread.assertBackgroundThread()
    let emulatorPath = try ADB.getEmulatorPath()
    var arguments = ["@\(device.name)"]
    let formattedArguments = additionalArgs
      .filter { !$0.isEmpty }
      .map { $0.hasPrefix("-") ? $0 : "-\($0)" }
    arguments.append(contentsOf: getAndroidLaunchParams())
    arguments.append(contentsOf: formattedArguments)
    do {
      try shell.execute(command: emulatorPath, arguments: arguments)
    } catch {
      // Ignore force qutting emulator (CMD + Q)
      if error.localizedDescription.contains("unexpected system image feature string") {
        return
      }
      throw error
    }
  }

  func getAndroidLaunchParams() -> [String] {
    guard let paramData = UserDefaults.standard.parameters else { return [] }
    guard let parameters = try? JSONDecoder().decode([Parameter].self, from: paramData) else {
      return []
    }

    return parameters.filter { $0.enabled }
      .map { $0.command }
  }
}

final class HarmonyDeviceService: DeviceServiceCommon {
  var shell: ShellProtocol = Shell()
  var device: Device

  init(device: Device) {
    self.device = device
  }

  func deleteDevice() throws {
    Thread.assertBackgroundThread()
    let emulatorPath = try HarmonyDeviceTool.getEmulatorPath()
    try shell.execute(command: emulatorPath, arguments: ["-delete", device.name])
  }

  func launchDevice(additionalArgs: [String]) throws {
    Thread.assertBackgroundThread()
    let emulatorPath = try HarmonyDeviceTool.getEmulatorPath()

    // The menu can contain a slightly stale snapshot of the device state.
    // Check DevEco again before starting to avoid launching a second instance.
    if let output = try? shell.execute(command: emulatorPath, arguments: ["-list", "-details"]),
       HarmonySimulatorParser().parse(output).contains(where: { $0.name == device.name && $0.booted }) {
      return
    }

    do {
      let launchPath = try HarmonyDeviceTool.getLaunchEmulatorPath(sourcePath: emulatorPath)
      try HarmonyDeviceTool.launch(
        path: launchPath,
        arguments: HarmonyDeviceTool.launchArguments(
          for: device.name,
          additionalArgs: additionalArgs
        ),
        deviceName: device.name
      )
    } catch {
      throw DeviceError.harmonyEmulatorLaunchFailed
    }
  }

  func focusDevice() {
    Thread.assertBackgroundThread()

    let runningApplications = NSWorkspace.shared.runningApplications
    let emulatorApplication = runningApplications.first { application in
      guard let bundlePath = application.bundleURL?.path else { return false }
      return bundlePath.contains("DevEco-Studio.app")
        || bundlePath.contains("/HarmonyEmulator.app")
        || bundlePath.hasSuffix("/Emulator")
    }
    emulatorApplication?.activate(options: [.activateIgnoringOtherApps])
  }
}
