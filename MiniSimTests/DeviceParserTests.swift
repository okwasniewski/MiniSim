@testable import MiniSim
import XCTest

class DeviceParserTests: XCTestCase {
  // Mock ADB class for testing
  class ADB: ADBProtocol {
    static func sendText(device: Device, text: String) throws {
    }

    static func launchLogCat(device: Device) throws {
    }

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

  func testIOSSimulatorParser() throws {
    let parser = IOSSimulatorParser()
    let input = """
        {
          "devices" : {
            "com.apple.CoreSimulator.SimRuntime.iOS-17-5" : [
              {
                "name" : "iPhone SE (3rd generation)",
                "udid" : "957C8A2F-4C12-4732-A4E9-37F8FDD35E3B",
                "state" : "Booted",
                "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
                "isAvailable" : true
              },
              {
                "name" : "iPhone 15",
                "udid" : "7B8464FF-956F-405B-B357-8ED4689E5177",
                "state" : "Shutdown",
                "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
                "isAvailable" : true
              },
              {
                "name" : "iPad Pro 11-inch (M4)",
                "udid" : "7EF89937-90BE-41E5-BD53-03BA6050D63F",
                "state" : "Shutdown",
                "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-8GB",
                "isAvailable" : true
              }
            ],
            "com.apple.CoreSimulator.SimRuntime.watchOS-26-0" : [
              {
                "name" : "Apple Watch Series 11 (46mm)",
                "udid" : "2E4CC9E0-16C8-4149-9150-B74817AF94A5",
                "state" : "Shutdown",
                "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11-46mm",
                "isAvailable" : true
              },
              {
                "name" : "iPhone 17 Pro with Apple Watch",
                "udid" : "B7D730BC-9239-48B3-BA20-6CF5A666B526",
                "state" : "Shutdown",
                "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
                "isAvailable" : true
              }
            ],
            "com.apple.CoreSimulator.SimRuntime.visionOS-2-5" : [
              {
                "name" : "Apple Vision Pro",
                "udid" : "CD50D0C6-D8F6-424E-B1C2-1C288EDBBD79",
                "state" : "Shutdown",
                "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.Apple-Vision-Pro",
                "isAvailable" : true
              }
            ]
          }
        }
        """

    let devices = parser.parse(input)

    XCTAssertEqual(devices.count, 6)

    let iPhoneSE = try XCTUnwrap(devices.first { $0.identifier == "957C8A2F-4C12-4732-A4E9-37F8FDD35E3B" })
    XCTAssertEqual(iPhoneSE.name, "iPhone SE (3rd generation)")
    XCTAssertEqual(iPhoneSE.version, "iOS 17.5")
    XCTAssertTrue(iPhoneSE.booted)
    XCTAssertEqual(iPhoneSE.platform, .ios)
    XCTAssertEqual(iPhoneSE.type, .virtual)
    XCTAssertEqual(iPhoneSE.deviceFamily, .iPhone)

    let iPhone15 = try XCTUnwrap(devices.first { $0.identifier == "7B8464FF-956F-405B-B357-8ED4689E5177" })
    XCTAssertEqual(iPhone15.name, "iPhone 15")
    XCTAssertEqual(iPhone15.version, "iOS 17.5")
    XCTAssertFalse(iPhone15.booted)
    XCTAssertEqual(iPhone15.platform, .ios)
    XCTAssertEqual(iPhone15.type, .virtual)
    XCTAssertEqual(iPhone15.deviceFamily, .iPhone)

    let iPadPro = try XCTUnwrap(devices.first { $0.identifier == "7EF89937-90BE-41E5-BD53-03BA6050D63F" })
    XCTAssertEqual(iPadPro.name, "iPad Pro 11-inch (M4)")
    XCTAssertEqual(iPadPro.deviceFamily, .iPad)

    let appleWatch = try XCTUnwrap(devices.first { $0.identifier == "2E4CC9E0-16C8-4149-9150-B74817AF94A5" })
    XCTAssertEqual(appleWatch.name, "Apple Watch Series 11 (46mm)")
    XCTAssertEqual(appleWatch.version, "watchOS 26.0")
    XCTAssertEqual(appleWatch.deviceFamily, .watch)

    // iPhone paired with Apple Watch should have iPhone device family
    let iPhoneWithWatch = try XCTUnwrap(devices.first { $0.identifier == "B7D730BC-9239-48B3-BA20-6CF5A666B526" })
    XCTAssertEqual(iPhoneWithWatch.name, "iPhone 17 Pro with Apple Watch")
    XCTAssertEqual(iPhoneWithWatch.deviceFamily, .iPhone)

    let visionPro = try XCTUnwrap(devices.first { $0.identifier == "CD50D0C6-D8F6-424E-B1C2-1C288EDBBD79" })
    XCTAssertEqual(visionPro.name, "Apple Vision Pro")
    XCTAssertEqual(visionPro.deviceFamily, .vision)
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
      static func sendText(device: Device, text: String) throws {
      }

      static func launchLogCat(device: Device) throws {
      }

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
