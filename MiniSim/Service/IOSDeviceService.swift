import Foundation

class IOSDeviceService: DeviceServiceCommon {
  var shell: ShellProtocol = Shell()
  var device: Device

  init(device: Device) {
    self.device = device
  }

  func deleteDevice() throws {
    Thread.assertBackgroundThread()
    if let uuid = device.identifier {
      try shell.execute(command: DeviceConstants.ProcessPaths.xcrun.rawValue, arguments: ["simctl", "delete", uuid])
    }
  }

  func launchDevice(additionalArgs: [String]) throws {
    Thread.assertBackgroundThread()
    do {
      let uuid = device.identifier ?? ""
      try AppleUtils.launchSimulatorApp(uuid: uuid)
      try shell.execute(command: DeviceConstants.ProcessPaths.xcrun.rawValue, arguments: ["simctl", "boot", uuid])
    } catch {
      if !error.localizedDescription.contains(DeviceConstants.deviceBootedError) {
        throw error
      }
    }
  }
}
