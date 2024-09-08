//
//  Adb.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 01/02/2023.
//

import Foundation

protocol ADBProtocol {
    static var shell: ShellProtocol { get set }

    static func getAdbPath() throws -> String
    static func getEmulatorPath() throws -> String
    static func getAndroidHome() throws -> String
    static func getAdbId(for deviceName: String) throws -> String
    static func checkAndroidHome(
        path: String,
        fileManager: FileManager
    ) throws -> Bool
    static func isAccesibilityOn(deviceId: String) -> Bool
    static func toggleAccesibility(deviceId: String)
}

final class ADB: ADBProtocol {
    static var shell: ShellProtocol = Shell()

    static let talkbackOn = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
    static let talkbackOff = "com.android.talkback/com.google.android.marvin.talkback.TalkBackService"

    private enum Paths: String {
        case home = "/Android/sdk"
        case emulator = "/emulator/emulator"
        case adb = "/platform-tools/adb"
        case avd = "/cmdline-tools/latest/bin/avdmanager"
    }

    /**
     Gets `ANDROID_HOME` path. First checks in UserDefaults if androidHome exists
     if not defaults to:  `/Users/<name>/Library/Android/sdk`.
     */
    static func getAndroidHome() throws -> String {
        if let savedAndroidHome = UserDefaults.standard.androidHome, !savedAndroidHome.isEmpty {
            return savedAndroidHome
        }

        let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        guard let path = libraryDirectory.first else {
            throw DeviceError.androidStudioError
        }

        return path + Paths.home.rawValue
    }

    static func getAdbPath() throws -> String {
        try getAndroidHome() + Paths.adb.rawValue
    }

    static func getAvdPath() throws -> String {
        try getAndroidHome() + Paths.avd.rawValue
    }

    /**
     Checks if passed path exists and points to `ANDROID_HOME`.
     */
    @discardableResult static func checkAndroidHome(
        path: String,
        fileManager: FileManager = .default
    ) throws -> Bool {
        if !fileManager.fileExists(atPath: path) {
            throw AndroidHomeError.pathNotFound
        }

        do {
            try shell.execute(command: "\(path)" + Paths.emulator.rawValue, arguments: ["-list-avds"])
        } catch {
            throw AndroidHomeError.pathNotCorrect
        }
        return true
    }

    static func getEmulatorPath() throws -> String {
        try getAndroidHome() + Paths.emulator.rawValue
    }

    static func getAdbId(for deviceName: String) throws -> String {
        let adbPath = try Self.getAdbPath()
        let onlineDevices = try shell.execute(command: "\(adbPath) devices")
        let splitted = onlineDevices.components(separatedBy: "\n")

        for line in splitted {
            let device = line.match("^emulator-[0-9]+")
            guard let deviceId = device.first?.first else { continue }

            let output = try? shell.execute(
                command: "\(adbPath) -s \(deviceId) emu avd name"
            )
            .components(separatedBy: "\n")

            if let name = output?.first {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDeviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedName == trimmedDeviceName {
                    return deviceId
                }
            }
        }
        throw DeviceError.deviceNotFound
    }

    static func isAccesibilityOn(deviceId: String) -> Bool {
        guard let adbPath = try? Self.getAdbPath() else {
            return false
        }
        let shellCommand = "\(adbPath) -s \(deviceId) shell settings get secure enabled_accessibility_services"
        guard let result = try? shell.execute(command: shellCommand) else {
            return false
        }

        if result == talkbackOn {
            return true
        }

        return false
    }

    static func toggleAccesibility(deviceId: String) {
        guard let adbPath = try? Self.getAdbPath() else {
            return
        }
        let a11yIsEnabled = Self.isAccesibilityOn(deviceId: deviceId)
        let value = a11yIsEnabled ? ADB.talkbackOff : ADB.talkbackOn
        let shellCmd = "\(adbPath) -s \(deviceId) shell settings put secure enabled_accessibility_services \(value)"

        // Ignore the error if toggling a11y fails.
        _ = try? shell.execute(command: shellCmd)
    }
}
