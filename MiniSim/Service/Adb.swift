//
//  Adb.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 01/02/2023.
//

import Foundation
import ShellOut

protocol ADBProtocol {
    static func getAdbPath() throws -> String
    static func getEmulatorPath() throws -> String
    static func getAdbId(for deviceName: String, adbPath: String) throws -> String
    static func checkAndroidHome(path: String) throws -> Bool
    static func isAccesibilityOn(deviceId: String, adbPath: String) -> Bool
}

final class ADB: ADBProtocol {
    
    static let talkbackOn = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
    static let talkbackOff = "com.android.talkback/com.google.android.marvin.talkback.TalkBackService"
    
    private enum Paths: String {
        case home = "/Android/sdk"
        case emulator = "/emulator/emulator"
        case adb = "/platform-tools/adb"
    }
    
    /**
     Gets `ANDROID_HOME` path. First checks in UserDefaults if androidHome exists if not defaults to:  `/Users/<name>/Library/Android/sdk`.
     */
    static func getAndroidHome() throws -> String {
        if let savedAndroidHome = UserDefaults.standard.androidHome, !savedAndroidHome.isEmpty {
            return savedAndroidHome
        }
        
        let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        guard let path = libraryDirectory.first else {
            throw DeviceError.AndroidStudioError
        }
        
        return path + Paths.home.rawValue
    }
    
    static func getAdbPath() throws -> String {
        return try getAndroidHome() + Paths.adb.rawValue
    }
    
    /**
     Checks if passed path exists and points to `ANDROID_HOME`.
     */
    @discardableResult static func checkAndroidHome(path: String) throws -> Bool {
        if !FileManager.default.fileExists(atPath: path) {
            throw AndroidHomeError.pathNotFound
        }
        
        do {
            try shellOut(to: "\(path)" + Paths.emulator.rawValue, arguments: ["-list-avds"])
        } catch {
            throw AndroidHomeError.pathNotCorrect
        }
        return true
    }
    
    static func getEmulatorPath() throws -> String {
        return try getAndroidHome() + Paths.emulator.rawValue
    }
    
    static func getAdbId(for deviceName: String, adbPath: String) throws -> String {
        let onlineDevices = try shellOut(to: "\(adbPath) devices")
        let splitted = onlineDevices.components(separatedBy: "\n")
        
        for line in splitted {
            let device = line.match("^emulator-[0-9]+")
            guard let deviceId = device.first?.first else { continue }
            let output = try? shellOut(to: "\(adbPath) -s \(deviceId) emu avd name").components(separatedBy: "\n")
            if let name = output?.first {
                if name.trimmingCharacters(in: .whitespacesAndNewlines) == deviceName.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return deviceId
                }
            }
        }
        throw DeviceError.deviceNotFound
    }
    
    static func isAccesibilityOn(deviceId: String, adbPath: String) -> Bool {
        guard let result = try? shellOut(to: ["\(adbPath) -s \(deviceId) shell settings get secure enabled_accessibility_services"]) else { return false }
        
        if result == talkbackOn {
            return true
        }
        
        return false
    }
}
