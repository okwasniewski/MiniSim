import AppKit

class AppleUtils {
  static var shell: ShellProtocol = Shell()
  static var workspace: NSWorkspace = .shared

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
  let isSimulatorRunning = workspace.runningApplications
    .contains { $0.bundleIdentifier == "com.apple.iphonesimulator" }

  guard !isSimulatorRunning else { return }

  guard let activeDeveloperDir = try? shell.execute(
    command: DeviceConstants.ProcessPaths.xcodeSelect.rawValue,
    arguments: ["-p"]
  )
    .trimmingCharacters(in: .whitespacesAndNewlines),
    !activeDeveloperDir.isEmpty else {
    throw DeviceError.xcodeError
  }

  let fileManager = FileManager.default
  let developerURL = URL(fileURLWithPath: activeDeveloperDir)

  // Older Xcode: Simulator.app is inside Developer/Applications.
  let simulatorExecutable = developerURL
    .appendingPathComponent("Applications/Simulator.app/Contents/MacOS/Simulator")
    .path

  if fileManager.isExecutableFile(atPath: simulatorExecutable) {
    try shell.execute(
      command: simulatorExecutable,
      arguments: ["--args", "-CurrentDeviceUDID", uuid]
    )
    return
  }

  // Newer Xcode: DeviceHub.app is alongside the Developer directory.
  let deviceHubURL = developerURL
    .deletingLastPathComponent()
    .appendingPathComponent("Applications/DeviceHub.app")

  guard fileManager.fileExists(atPath: deviceHubURL.path) else {
    throw DeviceError.xcodeError
  }

  try shell.execute(
    command: "/usr/bin/open",
    arguments: ["-a", deviceHubURL.path]
  )
}

}
