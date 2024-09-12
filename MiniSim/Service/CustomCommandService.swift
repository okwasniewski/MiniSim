import Foundation

class CustomCommandService {
  static var shell: ShellProtocol = Shell()
  static var adb: ADBProtocol.Type = ADB.self

  static func getCustomCommands(platform: Platform, userDefaults: UserDefaults = UserDefaults.standard) -> [Command] {
    guard let commandsData = userDefaults.commands else { return [] }
    guard let commands = try? JSONDecoder().decode([Command].self, from: commandsData) else {
      return []
    }

    return commands.filter { $0.platform == platform }
  }

  static func getCustomCommand(
    platform: Platform,
    commandName: String,
    userDefaults: UserDefaults = UserDefaults.standard
  ) -> Command? {
    let commands = getCustomCommands(platform: platform, userDefaults: userDefaults)
    return commands.first { $0.name == commandName }
  }

  static func runCustomCommand(_ device: Device, command: Command) throws {
    var commandToExecute = command.command
      .replacingOccurrences(of: Variables.deviceName.rawValue, with: device.name)

    let deviceID = device.identifier ?? ""

    if command.platform == .android {
      commandToExecute = try commandToExecute
        .replacingOccurrences(of: Variables.adbPath.rawValue, with: adb.getAdbPath())
        .replacingOccurrences(of: Variables.adbId.rawValue, with: deviceID)
        .replacingOccurrences(of: Variables.androidHomePath.rawValue, with: adb.getAndroidHome())
    } else {
      commandToExecute = commandToExecute
        .replacingOccurrences(of: Variables.uuid.rawValue, with: deviceID)
        .replacingOccurrences(of: Variables.xcrunPath.rawValue, with: DeviceConstants.ProcessPaths.xcrun.rawValue)
    }

    do {
      try shell.execute(command: commandToExecute)
      if command.bootsDevice ?? false && command.platform == .ios {
        try? AppleUtils.launchSimulatorApp(uuid: deviceID)
      }
      NotificationCenter.default.post(name: .commandDidSucceed, object: nil)
    } catch {
      throw CustomCommandError.commandError(errorMessage: error.localizedDescription)
    }
  }
}
