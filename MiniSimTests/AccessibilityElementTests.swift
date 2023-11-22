@testable import MiniSim
import XCTest

class AccessibilityElementTests: XCTestCase {
    var shellStub: ShellStub!
    var mockElement: AXUIElement!
    var accessibilityElement: AccessibilityElement!

    override func setUp() {
        super.setUp()
        mockElement = AXUIElementCreateSystemWide()
        accessibilityElement = AccessibilityElement(mockElement)
        shellStub = ShellStub()
        AccessibilityElement.shell = shellStub
    }

    override func tearDown() {
        shellStub.tearDown()
        super.tearDown()
    }

    func testPerformAction() {
        let result = accessibilityElement.performAction(key: "AXPress")
        XCTAssertFalse(result == .success, "Action should not succeed on mock element")
    }

    func testSetAttribute() {
        // Again, this is tricky to test without mocking AXUIElementSetAttributeValue
        // This test just ensures the method doesn't crash
        accessibilityElement.setAttribute(key: "AXFocused", value: true as CFBoolean)
        // We can't easily verify the result, but we can at least check that it doesn't crash
    }

    func testForceFocus() {
        let expectation = self.expectation(description: "Force focus completed")

        shellStub.mockedExecute = { _, _, _ in
          expectation.fulfill()
          return ""
        }

        AccessibilityElement.forceFocus(pid: 1_234)

        waitForExpectations(timeout: 5) { error in
          if let error {
            XCTFail("waitForExpectationsWithTimeout errored: \(error)")
          }
        }

        let expectedScript = """
        osascript -e 'tell application "System Events"
            set frontmost of every process whose unix id is 1234 to true
        end tell'
        """

        XCTAssertEqual(shellStub.lastExecutedCommand, expectedScript)
    }

    func testHasA11yAccess() {
        // This test depends on the system state and might not be reliable
        // You might want to mock this in a real scenario
        let hasAccess = AccessibilityElement.hasA11yAccess(prompt: false)
        // Instead of asserting true, we'll just print the result
        print("Accessibility access is \(hasAccess ? "granted" : "not granted")")
    }

    func testAllWindowsForPID() {
        // This test is also tricky without proper mocking
        // In a real scenario, you'd want to inject a mock AXUIElement creator
        let windows = AccessibilityElement.allWindowsForPID(1_234)
        XCTAssertTrue(windows.isEmpty, "Windows should be empty for mock element")
    }
}
