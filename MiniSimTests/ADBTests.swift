import XCTest

@testable import MiniSim

class FileManagerStub: FileManager {
    override func fileExists(atPath path: String) -> Bool {
        true
    }
}

class FileManagerEmptyStub: FileManager {
    override func fileExists(atPath path: String) -> Bool {
        false
    }
}

final class ADBTests: XCTestCase {
    let savedAndroidHome = UserDefaults.standard.androidHome
    let defaultHomePath = "/Users/\(NSUserName())/Library/Android/sdk"

    override func setUp() {
        ADB.shell = ShellStub.self
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.androidHome)
    }

    override func tearDown() {
        UserDefaults.standard.androidHome = savedAndroidHome
        ShellStub.tearDown()
    }

    func testGetAndroidHome() throws {
        let androidHome = try ADB.getAndroidHome()

        XCTAssertEqual(androidHome, defaultHomePath)

        UserDefaults.standard.androidHome = "customAndroidHome"
        let customAndroidHome = try ADB.getAndroidHome()

        XCTAssertEqual(
            customAndroidHome,
            "customAndroidHome",
            "Setting custom androidHome overrides default one"
        )
    }

    func testCheckAndroidHome() throws {
        let output = try ADB.checkAndroidHome(
            path: defaultHomePath,
            fileManager: FileManagerStub()
        )
        XCTAssertEqual(output, true)
        XCTAssertEqual(ShellStub.lastExecutedCommand, defaultHomePath + "/emulator/emulator")
        XCTAssertEqual(ShellStub.lastPassedArguments, ["-list-avds"])

        XCTAssertThrowsError(
            try ADB.checkAndroidHome(
                path: defaultHomePath,
                fileManager: FileManagerEmptyStub()
            )
        )
    }

    func testGetUtilPaths() throws {
        let adbPath = try ADB.getAdbPath()
        let avdPath = try ADB.getAvdPath()

        XCTAssertEqual(
            adbPath,
            defaultHomePath + "/platform-tools/adb"
        )
        XCTAssertEqual(
            avdPath,
            defaultHomePath + "/cmdline-tools/latest/bin/avdmanager"
        )
    }

    func testGetAdbId() throws {
        ShellStub.mockedExecute = { command, _, _ in
            if command.contains("devices") {
                return """
                List of devices attached
                emulator-5554    device
                emulator-5556    device
                """
            }

            if command.contains("avd name") {
                return """
                Pixel_XL_API_32
                OK
                """
            }

            return ""
        }
        let adbId = try ADB.getAdbId(for: "Pixel_XL_API_32")

        XCTAssertEqual(adbId, "emulator-5554")

        XCTAssertThrowsError(
            try ADB.getAdbId(for: "Pixel_Not_Found")
        )
    }

    func testIsAccesibilityOn() throws {
        var isA11yOn: Bool
        isA11yOn = ADB.isAccesibilityOn(deviceId: "emulator-5544")
        XCTAssertFalse(isA11yOn)

        ShellStub.mockedExecute = { _, _, _ in
            "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
        }
        isA11yOn = ADB.isAccesibilityOn(deviceId: "emulator-5544")
        XCTAssertTrue(isA11yOn)
    }

    func testToggle11y() {
        UserDefaults.standard.androidHome = "adbPath"
        let expectedCommand = """
        adbPath/platform-tools/adb -s emulator-5544 shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
        """

        ADB.toggleAccesibility(deviceId: "emulator-5544")
        XCTAssertEqual(ShellStub.lastExecutedCommand, expectedCommand)
        XCTAssertEqual(ShellStub.lastPassedArguments, [])
    }
}
