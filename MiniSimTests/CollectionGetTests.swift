import XCTest

@testable import MiniSim

final class CollectionGetTests: XCTestCase {
  func testGetAtValidIndex() {
    let array = ["a", "b", "c"]

    XCTAssertEqual(array.get(at: 0), "a")
    XCTAssertEqual(array.get(at: 1), "b")
    XCTAssertEqual(array.get(at: 2), "c")
  }

  func testGetAtInvalidIndex() {
    let array = ["a", "b", "c"]

    XCTAssertNil(array.get(at: 3))
    XCTAssertNil(array.get(at: 100))
  }

  func testGetOnEmptyCollection() {
    let array: [String] = []

    XCTAssertNil(array.get(at: 0))
  }

  func testGetWithDifferentTypes() {
    let intArray = [1, 2, 3]
    XCTAssertEqual(intArray.get(at: 1), 2)

    let deviceArray = [
      Device(name: "iPhone", identifier: "uuid1", platform: .ios, type: .virtual),
      Device(name: "Pixel", identifier: "uuid2", platform: .android, type: .virtual)
    ]
    XCTAssertEqual(deviceArray.get(at: 0)?.name, "iPhone")
    XCTAssertEqual(deviceArray.get(at: 1)?.platform, .android)
    XCTAssertNil(deviceArray.get(at: 2))
  }

  func testGetOnDictionary() {
    let dict = ["a": 1, "b": 2]
    let keys = Array(dict.keys).sorted()

    XCTAssertNotNil(keys.get(at: 0))
    XCTAssertNil(keys.get(at: 10))
  }
}
