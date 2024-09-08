@testable import MiniSim
import XCTest

class DeviceParserTests: XCTestCase {
  // Mock ADB class for testing
  class ADB: ADBProtocol {
    static var shell: ShellProtocol = Shell()

    static func getAndroidHome() throws -> String {
      ""
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
      "/mock/adb/path"
    }
  }

  func testDeviceParserFactory() {
    let iosParser = DeviceParserFactory().getParser(.iosSimulator)
    XCTAssertTrue(iosParser is IOSSimulatorParser)

    let androidParser = DeviceParserFactory().getParser(.androidEmulator)
    XCTAssertTrue(androidParser is AndroidEmulatorParser)
  }

  func testIOSSimulatorParser() {
    let parser = IOSSimulatorParser()
    let input = """
        == Devices ==
        -- iOS 17.5 --
            iPhone SE (3rd generation) (957C8A2F-4C12-4732-A4E9-37F8FDD35E3B) (Booted)
            iPhone 15 (7B8464FF-956F-405B-B357-8ED4689E5177) (Shutdown)
            iPhone 15 Plus (37A0352D-849D-463B-B513-D23ED0113A87) (Booted)
            iPhone 15 Pro (9536A75B-5B77-40D8-B96D-925A60E5C0ED) (Shutdown)
            iPhone 15 Pro Max (7ADF6567-9F08-42A4-A709-2460879038A7) (Shutdown)
            iPad (10th generation) (D923D804-5E6C-4039-9095-294F7EE2EF3C) (Shutdown)
            iPad mini (6th generation) (FD14D0FA-7D9A-4107-B73F-B137B7B61515) (Shutdown)
            iPad Air 11-inch (M2) (67454794-F54F-43DB-868E-7798B32599D9) (Shutdown)
            iPad Air 13-inch (M2) (2BF9FCDF-EF46-4340-BF90-5DA59AA9F55C) (Shutdown)
            iPad Pro 11-inch (M4) (7EF89937-90BE-41E5-BD53-03BA6050D63F) (Shutdown)
            iPad Pro 13-inch (M4) (0F74471B-3D0C-4EDA-9D65-E6A430217294) (Shutdown)
        -- visionOS 1.2 --
            Apple Vision Pro (CD50D0C6-D8F6-424E-B1C2-1C288EDBBD79) (Shutdown)
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.iOS-15-5 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.iOS-16-1 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.iOS-17-0 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.iOS-17-2 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.iOS-17-4 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.tvOS-15-4 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.tvOS-16-1 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.watchOS-8-5 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.xrOS-1-0 --
        -- Unavailable: com.apple.CoreSimulator.SimRuntime.xrOS-1-1 --
        """

    let devices = parser.parse(input)

    XCTAssertEqual(devices.count, 12)

    XCTAssertEqual(devices[0].name, "iPhone SE (3rd generation)")
    XCTAssertEqual(devices[0].version, "iOS 17.5")
    XCTAssertEqual(devices[0].identifier, "957C8A2F-4C12-4732-A4E9-37F8FDD35E3B")
    XCTAssertTrue(devices[0].booted)
    XCTAssertEqual(devices[0].platform, .ios)
    XCTAssertEqual(devices[0].type, .virtual)

    XCTAssertEqual(devices[1].name, "iPhone 15")
    XCTAssertEqual(devices[1].version, "iOS 17.5")
    XCTAssertEqual(devices[1].identifier, "7B8464FF-956F-405B-B357-8ED4689E5177")
    XCTAssertFalse(devices[1].booted)
    XCTAssertEqual(devices[1].platform, .ios)
    XCTAssertEqual(devices[1].type, .virtual)

    XCTAssertEqual(devices[2].name, "iPhone 15 Plus")
    XCTAssertEqual(devices[2].version, "iOS 17.5")
    XCTAssertEqual(devices[2].identifier, "37A0352D-849D-463B-B513-D23ED0113A87")
    XCTAssertTrue(devices[2].booted)
    XCTAssertEqual(devices[2].platform, .ios)
    XCTAssertEqual(devices[2].type, .virtual)
  }

  func testAndroidEmulatorParser() {
    let parser = AndroidEmulatorParser(adb: ADB.self)
    let input = """
        Pixel_3a_API_30_x86
        Pixel_4_API_29
        Nexus_5X_API_28
        """

    let devices = parser.parse(input)

    XCTAssertEqual(devices.count, 3)

    XCTAssertEqual(devices[0].name, "Pixel_3a_API_30_x86")
    XCTAssertEqual(devices[0].identifier, "mock_adb_id_for_Pixel_3a_API_30_x86")
    XCTAssertTrue(devices[0].booted)
    XCTAssertEqual(devices[0].platform, .android)
    XCTAssertEqual(devices[0].type, .virtual)

    XCTAssertEqual(devices[1].name, "Pixel_4_API_29")
    XCTAssertEqual(devices[1].identifier, "mock_adb_id_for_Pixel_4_API_29")
    XCTAssertTrue(devices[1].booted)
    XCTAssertEqual(devices[1].platform, .android)
    XCTAssertEqual(devices[1].type, .virtual)

    XCTAssertEqual(devices[2].name, "Nexus_5X_API_28")
    XCTAssertEqual(devices[2].identifier, nil)
    XCTAssertFalse(devices[2].booted)
    XCTAssertEqual(devices[2].platform, .android)
    XCTAssertEqual(devices[2].type, .virtual)
  }

  func testAndroidPhysicalDeviceParser() {
    let parser = AndroidPhysicalDeviceParser()
    let emptyInput = """
        List of devices attached

        """

    var devices = parser.parse(emptyInput)
    XCTAssertEqual(devices.count, 0)

    let singleEmulatorInput = """
      List of devices attached
      emulator-5554          device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a transport_id:3

      """

    devices = parser.parse(singleEmulatorInput)
    XCTAssertEqual(devices.count, 0)

    let singlePhysicalDeviceInput = """
      List of devices attached
      RFCWA0FXXXX            device 0-1 product:a34xdxx model:SM_A346E device:a34x transport_id:5

      """

    devices = parser.parse(singlePhysicalDeviceInput)
    XCTAssertEqual(devices.count, 1)

    XCTAssertEqual(devices[0].name, "SM_A346E")
    XCTAssertEqual(devices[0].identifier, "RFCWA0FXXXX")
    XCTAssertTrue(devices[0].booted)
    XCTAssertEqual(devices[0].platform, .android)
    XCTAssertEqual(devices[0].type, .physical)

    let mixedInput = """
      List of devices attached
      emulator-5554          device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a transport_id:3
      RFCWA0FXXXX            device 0-1 product:a34xdxx model:SM_A346E device:a34x transport_id:5

      """

    devices = parser.parse(mixedInput)
    XCTAssertEqual(devices.count, 1)

    XCTAssertEqual(devices[0].name, "SM_A346E")
    XCTAssertEqual(devices[0].identifier, "RFCWA0FXXXX")
    XCTAssertTrue(devices[0].booted)
    XCTAssertEqual(devices[0].platform, .android)
    XCTAssertEqual(devices[0].type, .physical)
  }

  func testIOSPhysicalDeviceParser() {
    let parser = IOSPhysicalDeviceParser()
    let emptyInput = """
        """

    var devices = parser.parse(emptyInput)
    XCTAssertEqual(devices.count, 0)

    let invalidInput = """
      some random text
      """

    devices = parser.parse(invalidInput)
    XCTAssertEqual(devices.count, 0)

    let unsuccessfulOutcomeInput = """
      {
        "info" : {
          "outcome" : "success",
        }
      }
      """

    devices = parser.parse(unsuccessfulOutcomeInput)
    XCTAssertEqual(devices.count, 0)

    let validInput = """
      {
        "info" : {
          "outcome" : "success",
        },
        "result" : {
          "devices" : [
            {
              "connectionProperties" : {
                "tunnelState" : "connected"
              },
              "deviceProperties" : {
                "name" : "Random iPhone 1",
                "osVersionNumber" : "17.6.1",
              },
              "hardwareProperties" : {
                "udid" : "xxx-xxx-xxx1"
              },
            },
            {
              "connectionProperties" : {
                "tunnelState" : "unavailable"
              },
              "deviceProperties" : {
                "name" : "Random iPhone 2",
                "osVersionNumber" : "17.6.2",
              },
              "hardwareProperties" : {
                "udid" : "xxx-xxx-xxx2"
              },
            }
          ]
        }
      }
      """

    devices = parser.parse(validInput)
    XCTAssertEqual(devices.count, 2)

    XCTAssertEqual(devices[0].name, "Random iPhone 1")
    XCTAssertEqual(devices[0].identifier, "xxx-xxx-xxx1")
    XCTAssertTrue(devices[0].booted)
    XCTAssertTrue(devices[0].booted)
    XCTAssertEqual(devices[0].version, "17.6.1")
    XCTAssertEqual(devices[0].platform, .ios)
    XCTAssertEqual(devices[0].type, .physical)

    XCTAssertEqual(devices[1].name, "Random iPhone 2")
    XCTAssertEqual(devices[1].identifier, "xxx-xxx-xxx2")
    XCTAssertFalse(devices[1].booted)
    XCTAssertEqual(devices[1].version, "17.6.2")
    XCTAssertEqual(devices[1].platform, .ios)
    XCTAssertEqual(devices[1].type, .physical)
  }

  func filtersOutEmulatorCrashData() {
    let parser = AndroidEmulatorParser(adb: ADB.self)
    let input = """
        Pixel_3a_API_30_x86
        INFO    | Storing crashdata in: /tmp/android-test/emu-crash-34.1.20.db, detection is enabled for process: 58515
        """

    let devices = parser.parse(input)

    XCTAssertEqual(devices.count, 1)

    XCTAssertEqual(devices[0].name, "Pixel_3a_API_30_x86")
    XCTAssertEqual(devices[0].identifier, "mock_adb_id_for_Pixel_3a_API_30_x86")
    XCTAssertTrue(devices[0].booted)
    XCTAssertEqual(devices[0].platform, .android)
    XCTAssertEqual(devices[0].type, .virtual)

    XCTAssertNil(devices.first { $0.name.contains("crashdata") })
  }

  func testAndroidEmulatorParserWithADBFailure() {
    class FailingADB: ADBProtocol {
      static func getAndroidHome() throws -> String {
        ""
      }

      static var shell: ShellProtocol = Shell()

      static func getAdbId(for deviceName: String) throws -> String {
        throw NSError(domain: "ADBError", code: 2, userInfo: nil)
      }

      static func getAdbPath() throws -> String {
        throw NSError(domain: "ADBError", code: 1, userInfo: nil)
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
    }

    let parser = AndroidEmulatorParser(adb: FailingADB.self)
    let input = "Pixel_3a_API_30_x86"

    let devices = parser.parse(input)

    XCTAssertFalse(devices.isEmpty)
    XCTAssertEqual(devices[0].name, "Pixel_3a_API_30_x86")
    XCTAssertFalse(devices[0].booted)
  }
}
