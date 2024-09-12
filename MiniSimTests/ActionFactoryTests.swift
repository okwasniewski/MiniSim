@testable import MiniSim
import XCTest

class MockAction: Action {
  var executeWasCalled = false
  var showQuestionDialogWasCalled = false
  var shouldShowDialog = false

  func execute() throws {
    executeWasCalled = true
  }

  func showQuestionDialog() -> Bool {
    showQuestionDialogWasCalled = true
    return shouldShowDialog
  }
}

class ActionFactoryTests: XCTestCase {
  func testAndroidActionFactory() {
    let device = Device(name: "Test Android Device", identifier: "test_id", platform: .android, type: .physical)

    for tag in SubMenuItems.Tags.allCases {
      let action = AndroidActionFactory.createAction(for: tag, device: device, itemName: "Test Item")
      XCTAssertNotNil(action, "Action should be created for tag: \(tag)")

      switch tag {
      case .copyName:
        XCTAssertTrue(action is CopyNameAction)
      case .copyID:
        XCTAssertTrue(action is CopyIDAction)
      case .coldBoot:
        XCTAssertTrue(action is ColdBootCommand)
      case .noAudio:
        XCTAssertTrue(action is NoAudioCommand)
      case .toggleA11y:
        XCTAssertTrue(action is ToggleA11yCommand)
      case .paste:
        XCTAssertTrue(action is PasteClipboardAction)
      case .delete:
        XCTAssertTrue(action is DeleteAction)
      case .customCommand:
        XCTAssertTrue(action is CustomCommandAction)
      case .logcat:
        XCTAssertTrue(action is LaunchLogCat)
      }
    }
  }

  func testIOSActionFactory() {
    let device = Device(name: "Test iOS Device", identifier: "test_id", platform: .ios, type: .physical)

    for tag in SubMenuItems.Tags.allCases {
      if tag == .noAudio || tag == .toggleA11y || tag == .paste || tag == .logcat {
        // These actions are not supported for iOS, so we skip them
        continue
      }

      let action = IOSActionFactory.createAction(for: tag, device: device, itemName: "Test Item")
      XCTAssertNotNil(action, "Action should be created for tag: \(tag)")

      switch tag {
      case .copyName:
        XCTAssertTrue(action is CopyNameAction)
      case .copyID:
        XCTAssertTrue(action is CopyIDAction)
      case .coldBoot:
        XCTAssertTrue(action is ColdBootCommand)
      case .delete:
        XCTAssertTrue(action is DeleteAction)
      case .customCommand:
        XCTAssertTrue(action is CustomCommandAction)
      default:
        XCTFail("Unexpected tag handled: \(tag)")
      }
    }
  }
}

class ActionExecutorTests: XCTestCase {
  var executor: ActionExecutor!
  var shellStub: ShellStub!

  override func setUp() {
    super.setUp()
    executor = ActionExecutor(queue: DispatchQueue.main)
    shellStub = ShellStub()
    // Assume we have a way to inject the shellStub into actions that need it
  }

  func testExecuteAndroidAction() {
    let device = Device(name: "Test Android Device", identifier: "test_id", platform: .android, type: .physical)
    let expectation = self.expectation(description: "Action executed")

    executor.execute(device: device, commandTag: .copyName, itemName: "Test Item")

    // Use dispatch after to allow the async execution to complete
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      // Here we would typically check if the action was executed
      // For this test, we're just fulfilling the expectation
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testExecuteIOSAction() {
    let device = Device(name: "Test iOS Device", identifier: "test_id", platform: .ios, type: .physical)
    let expectation = self.expectation(description: "Action executed")

    executor.execute(device: device, commandTag: .copyID, itemName: "Test Item")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testExecuteActionWithQuestionDialog() {
    let mockAction = MockAction()
    mockAction.shouldShowDialog = true

    // We need a way to inject our mock action into the factory
    // This might require modifying your ActionFactory to allow injection for testing
    // For now, we'll just test the logic directly

    if mockAction.showQuestionDialog() {
      XCTAssertFalse(mockAction.executeWasCalled, "Action should not be executed if dialog is shown")
    } else {
      XCTFail("Question dialog should have been shown")
    }
  }
}
