@testable import MiniSim
import XCTest

class DeviceDiscoveryTests: XCTestCase {
  var androidDiscovery: AndroidDeviceDiscovery!
  var iosDiscovery: IOSDeviceDiscovery!
  var shellStub: ShellStub!

  override func setUp() {
    super.setUp()
    shellStub = ShellStub()
    androidDiscovery = AndroidDeviceDiscovery()
    androidDiscovery.shell = shellStub
    iosDiscovery = IOSDeviceDiscovery()
    iosDiscovery.shell = shellStub
  }

  override func tearDown() {
    shellStub.tearDown()
    super.tearDown()
  }

  // Android Tests
  func testAndroidDeviceDiscoveryCommands() throws {
    shellStub.mockedExecute = { command, arguments, _ in
      if command.hasSuffix("adb") {
        XCTAssertEqual(arguments, ["devices", "-l"])
        return "mock adb output"
      } else if command.hasSuffix("emulator") {
        XCTAssertEqual(arguments, ["-list-avds"])
        return "mock emulator output"
      }
      XCTFail("Unexpected command: \(command)")
      return ""
    }

    _ = try androidDiscovery.getDevices(type: .physical)
    _ = try androidDiscovery.getDevices(type: .virtual)
    _ = try androidDiscovery.getDevices()

    XCTAssertTrue(shellStub.lastExecutedCommand.contains("adb"))
  }

  func testAndroidCheckSetup() throws {
    shellStub.mockedExecute = { _, _, _ in
      "/path/to/android/sdk"
    }

    XCTAssertNoThrow(try androidDiscovery.checkSetup())
  }

  // iOS Tests
  func testIOSDeviceDiscoveryCommands() throws {
    shellStub.mockedExecute = { command, arguments, _ in
      XCTAssertEqual(command, DeviceConstants.ProcessPaths.xcrun.rawValue)
      if arguments.contains("devicectl") {
        XCTAssertTrue(arguments.contains("list"))
        XCTAssertTrue(arguments.contains("devices"))
        return ""
      } else if arguments.contains("simctl") {
        XCTAssertEqual(arguments, ["simctl", "list", "devices", "available"])
        return "mock simctl output"
      }
      XCTFail("Unexpected arguments: \(arguments)")
      return ""
    }

    _ = try iosDiscovery.getDevices(type: .physical)
    _ = try iosDiscovery.getDevices(type: .virtual)
    _ = try iosDiscovery.getDevices()

    XCTAssertTrue(shellStub.lastExecutedCommand.contains("xcrun"))
  }

  func testIOSCheckSetup() throws {
    let xcrunPath = DeviceConstants.ProcessPaths.xcrun.rawValue
    XCTAssertNoThrow(try iosDiscovery.checkSetup())
    XCTAssertTrue(FileManager.default.fileExists(atPath: xcrunPath))
  }
}
