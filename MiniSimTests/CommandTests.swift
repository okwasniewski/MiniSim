import XCTest

@testable import MiniSim

final class CommandTests: XCTestCase {
  func testEncodingDecoding() throws {
    let command = Command(
      name: "Test Command",
      command: "adb devices",
      icon: "terminal",
      platform: .android,
      needBootedDevice: true,
      bootsDevice: false,
      tag: 42
    )

    let encoded = try JSONEncoder().encode(command)
    let decoded = try JSONDecoder().decode(Command.self, from: encoded)

    XCTAssertEqual(decoded.name, command.name)
    XCTAssertEqual(decoded.command, command.command)
    XCTAssertEqual(decoded.icon, command.icon)
    XCTAssertEqual(decoded.platform, command.platform)
    XCTAssertEqual(decoded.needBootedDevice, command.needBootedDevice)
    XCTAssertEqual(decoded.bootsDevice, command.bootsDevice)
    XCTAssertEqual(decoded.tag, command.tag)
  }

  func testDecodingOptionalFieldsNil() throws {
    let json = """
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Test",
      "command": "echo test",
      "icon": "star",
      "platform": "ios",
      "needBootedDevice": false
    }
    """

    let data = json.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(Command.self, from: data)

    XCTAssertEqual(decoded.name, "Test")
    XCTAssertEqual(decoded.platform, .ios)
    XCTAssertNil(decoded.bootsDevice)
    XCTAssertNil(decoded.tag)
  }

  func testDecodingOptionalFieldsPresent() throws {
    let json = """
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Test",
      "command": "echo test",
      "icon": "star",
      "platform": "android",
      "needBootedDevice": true,
      "bootsDevice": true,
      "tag": 99
    }
    """

    let data = json.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(Command.self, from: data)

    XCTAssertEqual(decoded.bootsDevice, true)
    XCTAssertEqual(decoded.tag, 99)
  }

  func testCommandHashable() {
    let command1 = Command(
      name: "Test",
      command: "echo",
      icon: "star",
      platform: .ios,
      needBootedDevice: false
    )

    let command2 = Command(
      name: "Test",
      command: "echo",
      icon: "star",
      platform: .ios,
      needBootedDevice: false
    )

    // Different UUIDs, so not equal
    XCTAssertNotEqual(command1, command2)

    // Same command in set should work
    var commandSet: Set<Command> = []
    commandSet.insert(command1)
    commandSet.insert(command2)
    XCTAssertEqual(commandSet.count, 2)
  }

  func testCommandIdentifiable() {
    let command = Command(
      name: "Test",
      command: "echo",
      icon: "star",
      platform: .ios,
      needBootedDevice: false
    )

    XCTAssertNotNil(command.id)
  }
}
