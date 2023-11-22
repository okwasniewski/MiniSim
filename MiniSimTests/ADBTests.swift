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
        XCTAssertEqual(ShellStub.executedCommand, defaultHomePath + "/emulator/emulator")
        XCTAssertEqual(ShellStub.passedParameters, ["-list-avds"])

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
}
