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
