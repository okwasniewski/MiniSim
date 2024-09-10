import AppKit

class AppleUtils {
  static var shell: ShellProtocol = Shell()

  static func clearDerivedData(
    completionQueue: DispatchQueue = .main,
    completion: @escaping (String, Error?) -> Void
  ) {
    DispatchQueue.global(qos: .background).async {
      do {
        let amountCleared = try? shell.execute(command: "du -sh \(DeviceConstants.derivedDataLocation)")
          .match(###"\d+\.?\d+\w+"###).first?.first
        try shell.execute(command: "rm -rf \(DeviceConstants.derivedDataLocation)")
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

  static func launchSimulatorApp(uuid: String) throws {
    let isSimulatorRunning = NSWorkspace.shared.runningApplications
      .contains { $0.bundleIdentifier == "com.apple.iphonesimulator" }

    if !isSimulatorRunning {
      guard let activeDeveloperDir = try? shell.execute(
        command: DeviceConstants.ProcessPaths.xcodeSelect.rawValue,
        arguments: ["-p"]
      )
        .trimmingCharacters(in: .whitespacesAndNewlines) else {
        throw DeviceError.xcodeError
      }
      try shell.execute(
        command: "\(activeDeveloperDir)/Applications/Simulator.app/Contents/MacOS/Simulator",
        arguments: ["--args", "-CurrentDeviceUDID", uuid]
      )
    }
  }
}
