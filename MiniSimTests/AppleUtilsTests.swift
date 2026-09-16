@testable import MiniSim
import XCTest

class MockNSWorkspace: NSWorkspace {
  var mockRunningApplications: [NSRunningApplication] = []

  override var runningApplications: [NSRunningApplication] {
    mockRunningApplications
  }
}

class MockNSRunningApplication: NSRunningApplication {
  let mockBundleIdentifier: String?

  init(bundleIdentifier: String?) {
    self.mockBundleIdentifier = bundleIdentifier
    super.init()
  }

  override var bundleIdentifier: String? {
    mockBundleIdentifier
  }
}

class AppleUtilsTests: XCTestCase {
  var shellStub: ShellStub!
  var mockWorkspace: MockNSWorkspace!

  override func setUp() {
    super.setUp()
    shellStub = ShellStub()

    mockWorkspace = MockNSWorkspace()
    AppleUtils.shell = shellStub
    AppleUtils.workspace = mockWorkspace
  }

  override func tearDown() {
    shellStub.tearDown()
    AppleUtils.fileExists = { FileManager.default.fileExists(atPath: $0) }
    super.tearDown()
  }

  func testClearDerivedData() {
    let expectation = self.expectation(description: "Completion handler called")

    shellStub.mockedExecute = { command, _, _ in
      if command.contains("du -sh") {
        return "100M    \(DeviceConstants.derivedDataLocation)"
      }
      return ""
    }

    AppleUtils.clearDerivedData { amountCleared, error in
      XCTAssertEqual(amountCleared, "100M")
      XCTAssertNil(error)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 5, handler: nil)

    XCTAssertTrue(shellStub.lastExecutedCommand.contains("rm -rf"))
    XCTAssertTrue(shellStub.lastExecutedCommand.contains(DeviceConstants.derivedDataLocation))
  }

  func testClearDerivedDataWithError() {
    let expectation = self.expectation(description: "Completion handler called")

    shellStub.mockedExecute = { _, _, _ in
      throw NSError(domain: "TestError", code: 1, userInfo: nil)
    }

    AppleUtils.clearDerivedData { amountCleared, error in
      XCTAssertEqual(amountCleared, "")
      XCTAssertNotNil(error)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 5, handler: nil)
  }

  private func stubXcodeSelect(developerDir: String = "/Applications/Xcode.app/Contents/Developer") {
    shellStub.mockedExecute = { command, _, _ in
      if command == DeviceConstants.ProcessPaths.xcodeSelect.rawValue {
        return developerDir
      }
      return ""
    }
  }

  func testLaunchSimulatorAppWhenNotRunning() {
    let uuid = "test-uuid"
    mockWorkspace.mockRunningApplications = [] // Simulator not running
    stubXcodeSelect()
    // Xcode 26 and earlier: Simulator.app is present.
    AppleUtils.fileExists = { $0.hasSuffix("Developer/Applications/Simulator.app") }

    XCTAssertFalse(try AppleUtils.launchSimulatorApp(uuid: uuid))

    XCTAssertEqual(shellStub.lastExecutedCommand, DeviceConstants.ProcessPaths.open.rawValue)
    XCTAssertEqual(shellStub.lastPassedArguments, [
      "-a",
      "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app",
      "--args",
      "-CurrentDeviceUDID",
      uuid
    ])
  }

  func testLaunchSimulatorAppIgnoresLingeringTrampolineOnLegacyXcode() {
    let uuid = "test-uuid"
    // SimulatorTrampoline keeps running after Simulator.app quits, so it must not
    // count as "the simulator app is already running".
    mockWorkspace.mockRunningApplications = [
      MockNSRunningApplication(bundleIdentifier: "com.apple.CoreSimulator.SimulatorTrampoline")
    ]
    stubXcodeSelect()
    AppleUtils.fileExists = { $0.hasSuffix("Developer/Applications/Simulator.app") }

    XCTAssertFalse(try AppleUtils.launchSimulatorApp(uuid: uuid))

    XCTAssertEqual(shellStub.lastExecutedCommand, DeviceConstants.ProcessPaths.open.rawValue)
  }

  private func stubDeviceHubOnly() {
    // Xcode 27 removed Simulator.app; only Device Hub exists.
    AppleUtils.fileExists = { $0.hasSuffix("Contents/Applications/DeviceHub.app") }
  }

  func testLaunchSimulatorAppUsesDeepLinkOnXcode27() {
    let uuid = "test-uuid"
    mockWorkspace.mockRunningApplications = []
    stubXcodeSelect()
    stubDeviceHubOnly()

    XCTAssertTrue(try AppleUtils.launchSimulatorApp(uuid: uuid))

    // Device Hub ignores -CurrentDeviceUDID; the devices:// link targets the device.
    XCTAssertEqual(shellStub.lastExecutedCommand, DeviceConstants.ProcessPaths.open.rawValue)
    XCTAssertEqual(shellStub.lastPassedArguments, ["devices://device/open?id=\(uuid)"])
  }

  func testLaunchSimulatorAppDeepLinksEvenWhenDeviceHubAlreadyRunning() {
    let uuid = "other-uuid"
    // Device Hub already showing some other device: the deep link is what switches
    // focus, so it must still fire rather than returning early.
    mockWorkspace.mockRunningApplications = [
      MockNSRunningApplication(bundleIdentifier: DeviceConstants.BundleID.deviceHub.rawValue)
    ]
    stubXcodeSelect()
    stubDeviceHubOnly()

    XCTAssertTrue(try AppleUtils.launchSimulatorApp(uuid: uuid))

    XCTAssertEqual(shellStub.lastPassedArguments, ["devices://device/open?id=\(uuid)"])
  }

  func testLaunchSimulatorAppOpensDeviceHubWithoutDeepLinkWhenUuidIsEmpty() {
    mockWorkspace.mockRunningApplications = []
    stubXcodeSelect()
    stubDeviceHubOnly()

    XCTAssertTrue(try AppleUtils.launchSimulatorApp(uuid: ""))

    XCTAssertEqual(shellStub.lastPassedArguments, [
      "-a",
      "/Applications/Xcode.app/Contents/Applications/DeviceHub.app"
    ])
  }

  func testLaunchSimulatorAppThrowsWhenNoSimulatorAppInstalled() {
    mockWorkspace.mockRunningApplications = []
    stubXcodeSelect()
    AppleUtils.fileExists = { _ in false }

    XCTAssertThrowsError(try AppleUtils.launchSimulatorApp(uuid: "test-uuid")) { error in
      XCTAssertEqual(error as? DeviceError, DeviceError.xcodeError)
    }
  }

  func testLaunchSimulatorAppWhenAlreadyRunning() {
    let uuid = "test-uuid"
    mockWorkspace.mockRunningApplications = [
      MockNSRunningApplication(bundleIdentifier: DeviceConstants.BundleID.simulator.rawValue)
    ]
    stubXcodeSelect()
    AppleUtils.fileExists = { $0.hasSuffix("Developer/Applications/Simulator.app") }

    XCTAssertFalse(try AppleUtils.launchSimulatorApp(uuid: uuid))

    XCTAssertEqual(
      shellStub.lastExecutedCommand,
      DeviceConstants.ProcessPaths.xcodeSelect.rawValue,
      "Should resolve the app but never re-open Simulator.app when it is already running"
    )
  }

  func testLaunchSimulatorAppWithXcodeError() {
    shellStub.mockedExecute = { _, _, _ in
      throw DeviceError.xcodeError
    }

    XCTAssertThrowsError(try AppleUtils.launchSimulatorApp(uuid: "test-uuid")) { error in
      XCTAssertEqual(error as? DeviceError, DeviceError.xcodeError)
    }
  }
}
