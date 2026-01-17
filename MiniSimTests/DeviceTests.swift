import XCTest

@testable import MiniSim

final class DeviceTests: XCTestCase {
  func testDisplayNameIOSWithVersion() {
    let device = Device(
      name: "iPhone 15 Pro",
      version: "iOS 17.5",
      identifier: "test-uuid",
      booted: false,
      platform: .ios,
      type: .virtual
    )

    XCTAssertEqual(device.displayName, "iPhone 15 Pro - (iOS 17.5)")
  }

  func testDisplayNameIOSWithoutVersion() {
    let device = Device(
      name: "iPhone 15 Pro",
      version: nil,
      identifier: "test-uuid",
      booted: false,
      platform: .ios,
      type: .virtual
    )

    XCTAssertEqual(device.displayName, "iPhone 15 Pro")
  }

  func testDisplayNameAndroid() {
    let device = Device(
      name: "Pixel_5_API_33",
      version: "13",
      identifier: "emulator-5554",
      booted: true,
      platform: .android,
      type: .virtual
    )

    XCTAssertEqual(device.displayName, "Pixel_5_API_33")
  }

  func testEncodingDecoding() throws {
    let device = Device(
      name: "iPhone 15 Pro",
      version: "iOS 17.5",
      identifier: "test-uuid",
      booted: true,
      platform: .ios,
      type: .virtual
    )

    let encoded = try JSONEncoder().encode(device)
    let decoded = try JSONDecoder().decode(Device.self, from: encoded)

    XCTAssertEqual(decoded.name, device.name)
    XCTAssertEqual(decoded.version, device.version)
    XCTAssertEqual(decoded.identifier, device.identifier)
    XCTAssertEqual(decoded.booted, device.booted)
    XCTAssertEqual(decoded.platform, device.platform)
    XCTAssertEqual(decoded.type, device.type)
  }

  func testEncodingIncludesDisplayName() throws {
    let device = Device(
      name: "iPhone 15",
      version: "iOS 17.5",
      identifier: "uuid",
      booted: false,
      platform: .ios,
      type: .virtual
    )

    let encoded = try JSONEncoder().encode(device)
    let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

    XCTAssertEqual(json?["displayName"] as? String, "iPhone 15 - (iOS 17.5)")
  }
}
