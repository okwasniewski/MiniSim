import AppKit

class AppleUtils {
  static var shell: ShellProtocol = Shell()
  static var workspace: NSWorkspace = .shared
  static var fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }

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

  /// Xcode 27 removed `Contents/Developer/Applications` and replaced Simulator.app
  /// with Device Hub, which ships next to Instruments in `Contents/Applications`.
  /// Returns the GUI app to launch, or nil when neither is installed.
  static func simulatorApp(developerDir: String) -> (path: String, isDeviceHub: Bool)? {
    let simulator = "\(developerDir)/Applications/\(DeviceConstants.BundleURL.simulator.rawValue)"
    if fileExists(simulator) {
      return (simulator, false)
    }

    let deviceHub = URL(fileURLWithPath: developerDir)
      .deletingLastPathComponent()
      .appendingPathComponent("Applications")
      .appendingPathComponent(DeviceConstants.BundleURL.deviceHub.rawValue)
      .path
    if fileExists(deviceHub) {
      return (deviceHub, true)
    }

    return nil
  }

  /// Device Hub registers the `devices://` URL scheme. Opening this link launches it
  /// if needed and shows that device's own window, which is how a specific device is
  /// targeted on Xcode 27+ (`-CurrentDeviceUDID` is ignored by Device Hub).
  /// The call is idempotent: repeating it re-focuses the existing window.
  static func deviceHubDeepLink(uuid: String) -> String {
    "devices://device/open?id=\(uuid)"
  }

  /// Ensures the simulator GUI is running and showing `uuid`.
  /// Returns true when Device Hub handled it, meaning the device window is already
  /// focused and no accessibility fallback is needed.
  @discardableResult
  static func launchSimulatorApp(uuid: String) throws -> Bool {
    guard let activeDeveloperDir = try? shell.execute(
      command: DeviceConstants.ProcessPaths.xcodeSelect.rawValue,
      arguments: ["-p"]
    )
      .trimmingCharacters(in: .whitespacesAndNewlines),
      let app = simulatorApp(developerDir: activeDeveloperDir) else {
      throw DeviceError.xcodeError
    }

    if app.isDeviceHub {
      // Always fired, even when Device Hub is already up: it is what switches the
      // focused device, so an early return here would strand the user on the
      // previously opened one. An unknown uuid is a safe no-op.
      try shell.execute(
        command: DeviceConstants.ProcessPaths.open.rawValue,
        arguments: uuid.isEmpty ? ["-a", app.path] : [deviceHubDeepLink(uuid: uuid)]
      )
      return true
    }

    // Simulator.app ignores -CurrentDeviceUDID once running, so only launch it once.
    // Deliberately not checking SimulatorTrampoline here: it lingers after the GUI
    // quits, so treating it as "running" would suppress the launch entirely.
    let isSimulatorRunning = workspace.runningApplications
      .contains { $0.bundleIdentifier == DeviceConstants.BundleID.simulator.rawValue }

    guard !isSimulatorRunning else { return false }

    // Launch through LaunchServices rather than exec'ing the binary.
    try shell.execute(
      command: DeviceConstants.ProcessPaths.open.rawValue,
      arguments: ["-a", app.path, "--args", "-CurrentDeviceUDID", uuid]
    )
    return false
  }
}
