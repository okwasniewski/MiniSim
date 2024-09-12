@testable import MiniSim // Adjust this import to match your actual module name
import XCTest

class CustomCommandServiceTests: XCTestCase {
  class ADB: ADBProtocol {
    static var shell: ShellProtocol = Shell()

    static func sendText(device: Device, text: String) throws {}

    static func launchLogCat(device: Device) throws {}

    static func getAndroidHome() throws -> String {
      "mocked_android_home"
    }

    static func getAdbId(for deviceName: String) throws -> String {
      if deviceName == "Nexus_5X_API_28" {
        throw NSError(domain: "ADBError", code: 1, userInfo: nil)
      }
      return "mock_adb_id_for_\(deviceName)"
    }

    static func checkAndroidHome(path: String, fileManager: FileManager) throws -> Bool {
      true
    }

    static func isAccesibilityOn(deviceId: String) -> Bool {
      false
    }

    static func toggleAccesibility(deviceId: String) {
    }

    static func getEmulatorPath() throws -> String {
      ""
    }

    static func getAdbPath() throws -> String {
      "mocked_adb_path"
    }
  }

  var userDefaults: UserDefaults!
  var shellStub: ShellStub!

  override func setUp() {
    super.setUp()
    shellStub = ShellStub()
    userDefaults = UserDefaults(suiteName: #file)
    CustomCommandService.shell = shellStub
    CustomCommandService.adb = ADB.self
  }

  override func tearDown() {
    userDefaults.removeObject(forKey: "commands")
    CustomCommandService.shell = Shell()
    super.tearDown()
  }

  func testGetCustomCommands() {
    let commands = [
      Command(name: "Test1", command: "cmd1", icon: "icon1", platform: .ios, needBootedDevice: false),
      Command(name: "Test2", command: "cmd2", icon: "icon2", platform: .android, needBootedDevice: true)
    ]
    let encodedCommands = try? JSONEncoder().encode(commands)
    userDefaults.set(encodedCommands, forKey: "commands")

    let iosCommands = CustomCommandService.getCustomCommands(platform: .ios, userDefaults: userDefaults)
    let androidCommands = CustomCommandService.getCustomCommands(platform: .android, userDefaults: userDefaults)

    XCTAssertEqual(iosCommands.count, 1)
    XCTAssertEqual(iosCommands.first?.name, "Test1")
    XCTAssertEqual(androidCommands.count, 1)
    XCTAssertEqual(androidCommands.first?.name, "Test2")
  }

  func testGetCustomCommandsWithInvalidData() {
    userDefaults.set("Invalid Data", forKey: "commands")

    let commands = CustomCommandService.getCustomCommands(platform: .ios, userDefaults: userDefaults)

    XCTAssertTrue(commands.isEmpty)
  }

  func testGetCustomCommand() {
    let commands = [
      Command(name: "Test1", command: "cmd1", icon: "icon1", platform: .ios, needBootedDevice: false),
      Command(name: "Test2", command: "cmd2", icon: "icon2", platform: .android, needBootedDevice: true)
    ]
    let encodedCommands = try? JSONEncoder().encode(commands)
    userDefaults.set(encodedCommands, forKey: "commands")

    let iosCommand = CustomCommandService.getCustomCommand(
      platform: .ios,
      commandName: "Test1",
      userDefaults: userDefaults
    )
    let androidCommand = CustomCommandService.getCustomCommand(
      platform: .android,
      commandName: "Test2",
      userDefaults: userDefaults
    )
    let nonExistentCommand = CustomCommandService.getCustomCommand(
      platform: .ios,
      commandName: "NonExistent",
      userDefaults: userDefaults
    )

    XCTAssertNotNil(iosCommand)
    XCTAssertEqual(iosCommand?.name, "Test1")
    XCTAssertNotNil(androidCommand)
    XCTAssertEqual(androidCommand?.name, "Test2")
    XCTAssertNil(nonExistentCommand)
  }

  func testRunCustomCommandIOS() {
    let device = Device(name: "TestDevice", version: "15.0", identifier: "test-id", booted: true, platform: .ios, type: .virtual)
    let command = Command(name: "TestCommand", command: "$xcrun_path $uuid $device_name", icon: "icon", platform: .ios, needBootedDevice: true)

    XCTAssertNoThrow(try CustomCommandService.runCustomCommand(device, command: command))

    let expectedCommand = "\(DeviceConstants.ProcessPaths.xcrun.rawValue) test-id TestDevice"
    XCTAssertEqual(shellStub.lastExecutedCommand, expectedCommand)
  }

  func testRunCustomCommandAndroid() throws {
    let device = Device(name: "TestDevice", version: "11", identifier: "test-id", booted: true, platform: .android, type: .physical)
    let command = Command(name: "TestCommand", command: "$adb_path $adb_id $android_home_path $device_name", icon: "icon", platform: .android, needBootedDevice: true)

    XCTAssertNoThrow(try CustomCommandService.runCustomCommand(device, command: command))

    let expectedCommand = "mocked_adb_path test-id mocked_android_home TestDevice"
    XCTAssertEqual(shellStub.lastExecutedCommand, expectedCommand)
  }

  func testRunCustomCommandError() {
    let device = Device(name: "TestDevice", version: "15.0", identifier: "test-id", booted: true, platform: .ios, type: .virtual)
    let command = Command(name: "TestCommand", command: "invalid_command", icon: "icon", platform: .ios, needBootedDevice: true)
    shellStub.mockedExecute = { _, _, _ in
      throw NSError(domain: "TestError", code: 1, userInfo: nil)
    }

    XCTAssertThrowsError(try CustomCommandService.runCustomCommand(device, command: command)) { error in
      XCTAssertTrue(error is CustomCommandError)
      if case let CustomCommandError.commandError(errorMessage) = error {
        XCTAssertEqual(errorMessage, "The operation couldn’t be completed. (TestError error 1.)")
      } else {
        XCTFail("Unexpected error type")
      }
    }
  }
}
