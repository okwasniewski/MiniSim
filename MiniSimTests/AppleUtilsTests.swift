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

  func testLaunchSimulatorAppWhenNotRunning() {
    let uuid = "test-uuid"
    mockWorkspace.mockRunningApplications = [] // Simulator not running

    shellStub.mockedExecute = { command, _, _ in
      if command == DeviceConstants.ProcessPaths.xcodeSelect.rawValue {
        return "/Applications/Xcode.app/Contents/Developer"
      }
      return ""
    }

    XCTAssertNoThrow(try AppleUtils.launchSimulatorApp(uuid: uuid))

    XCTAssertEqual(shellStub.lastExecutedCommand, "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/Simulator")
    XCTAssertEqual(shellStub.lastPassedArguments, ["--args", "-CurrentDeviceUDID", uuid])
  }

  func testLaunchSimulatorAppWhenAlreadyRunning() {
    let uuid = "test-uuid"
    mockWorkspace.mockRunningApplications = [MockNSRunningApplication(bundleIdentifier: "com.apple.iphonesimulator")]

    XCTAssertNoThrow(try AppleUtils.launchSimulatorApp(uuid: uuid))

    XCTAssertTrue(shellStub.lastExecutedCommand.isEmpty, "Should not execute any command when simulator is already running")
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
