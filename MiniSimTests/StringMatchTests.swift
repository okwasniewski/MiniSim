import XCTest

@testable import MiniSim

final class StringMatchTests: XCTestCase {
  func testMatchWithValidPattern() {
    let input = "iPhone 15 Pro"
    let matches = input.match("iPhone")

    XCTAssertEqual(matches.count, 1)
    XCTAssertEqual(matches.first?.first, "iPhone")
  }

  func testMatchWithNoMatch() {
    let input = "iPhone 15 Pro"
    let matches = input.match("Android")

    XCTAssertTrue(matches.isEmpty)
  }

  func testMatchWithMultipleMatches() {
    let input = "abc123def456ghi789"
    let matches = input.match("[0-9]+")

    XCTAssertEqual(matches.count, 3)
    XCTAssertEqual(matches[0].first, "123")
    XCTAssertEqual(matches[1].first, "456")
    XCTAssertEqual(matches[2].first, "789")
  }

  func testMatchWithCaptureGroups() {
    let input = "emulator-5554"
    let matches = input.match("(emulator)-([0-9]+)")

    XCTAssertEqual(matches.count, 1)
    XCTAssertEqual(matches[0][0], "emulator-5554")
    XCTAssertEqual(matches[0][1], "emulator")
    XCTAssertEqual(matches[0][2], "5554")
  }

  func testMatchWithEmptyString() {
    let input = ""
    let matches = input.match("[a-z]+")

    XCTAssertTrue(matches.isEmpty)
  }

  func testMatchUUIDPattern() {
    let input = "iPhone 15 (957C8A2F-4C12-4732-A4E9-37F8FDD35E3B) (Booted)"
    let matches = input.match("[A-F0-9-]{36}")

    XCTAssertEqual(matches.count, 1)
    XCTAssertEqual(matches.first?.first, "957C8A2F-4C12-4732-A4E9-37F8FDD35E3B")
  }

  func testMatchEmulatorIdPattern() {
    let input = "emulator-5554          device"
    let matches = input.match("^emulator-[0-9]+")

    XCTAssertEqual(matches.count, 1)
    XCTAssertEqual(matches.first?.first, "emulator-5554")
  }
}
