import XCTest

@testable import MiniSim

final class UserDefaultsTests: XCTestCase {
    let savedParameters = UserDefaults.standard.parameters
    let savedCommands = UserDefaults.standard.commands
    let savedAndroidHome = UserDefaults.standard.androidHome
    let savedIsOnboardingFinished = UserDefaults.standard.isOnboardingFinished
    let savedEnableiOSSimulators = UserDefaults.standard.enableiOSSimulators
    let savedEnableAndroidEmulators = UserDefaults.standard.enableAndroidEmulators

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.parameters)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.commands)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.androidHome)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.isOnboardingFinished)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.enableiOSSimulators)
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.enableAndroidEmulators)
    }

    override func tearDown() {
        UserDefaults.standard.parameters = savedParameters
        UserDefaults.standard.commands = savedCommands
        UserDefaults.standard.androidHome = savedAndroidHome
        UserDefaults.standard.isOnboardingFinished = savedIsOnboardingFinished
        UserDefaults.standard.enableiOSSimulators = savedEnableiOSSimulators
        UserDefaults.standard.enableAndroidEmulators = savedEnableAndroidEmulators
    }

    func testDefaultValues() {
        XCTAssertEqual(UserDefaults.standard.parameters, nil)
        XCTAssertEqual(UserDefaults.standard.commands, nil)
        XCTAssertEqual(UserDefaults.standard.androidHome, nil)
        XCTAssertEqual(UserDefaults.standard.isOnboardingFinished, false)
        XCTAssertEqual(UserDefaults.standard.enableiOSSimulators, true)
        XCTAssertEqual(UserDefaults.standard.enableAndroidEmulators, true)
    }

    func testChangingParameters() {
        let parameters: [Parameter] = [.init(title: "First", command: "adb reverse")]
        let data = try? JSONEncoder().encode(parameters)
        UserDefaults.standard.parameters = data

        let newParameters = UserDefaults.standard.parameters
        let decoded = try? JSONDecoder().decode([Parameter].self, from: newParameters!)

        XCTAssertEqual(parameters, decoded)
    }

    func testChanging() {
        UserDefaults.standard.isOnboardingFinished = true
        UserDefaults.standard.enableiOSSimulators = false
        UserDefaults.standard.enableAndroidEmulators = false
        UserDefaults.standard.androidHome = "test"

        XCTAssertEqual(UserDefaults.standard.isOnboardingFinished, true)
        XCTAssertEqual(UserDefaults.standard.enableiOSSimulators, false)
        XCTAssertEqual(UserDefaults.standard.enableAndroidEmulators, false)
        XCTAssertEqual(UserDefaults.standard.androidHome, "test")
    }
}
