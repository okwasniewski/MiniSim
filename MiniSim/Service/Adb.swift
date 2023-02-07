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
    static func isAccesibilityOn(deviceId: String, adbPath: String) -> Bool
}

final class ADB: NSObject, ADBProtocol {
    
    static let talkbackOn = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
    static let talkbackOff = "com.android.talkback/com.google.android.marvin.talkback.TalkBackService"
    
    private enum ConfigLocation: String, CaseIterable {
        case zshrc = "~/.zshrc"
        case zprofile = "~/.zprofile"
        case bashrc = "~/.bashrc"
        case bash_profile = "~/.bash_profile"
    }
    
    private static func getSourceFileScript(file: String) -> String {
        return """
                file=\(file)
                if [ -f "$file" ]; then
                    source $file
                fi
                """
    }
    
    private static func getAndroidHome() throws -> String {
        var androidHome = ""
        do {
            for config in ConfigLocation.allCases {
                androidHome = try shellOut(to: [
                    self.getSourceFileScript(file: config.rawValue),
                    "echo $ANDROID_HOME"
                ])
                if !androidHome.isEmpty {
                    break
                }
            }
        } catch {
            // Ignore errors they can be thrown if user has incorrect setup
        }
        if androidHome.isEmpty {
            throw DeviceError.AndroidStudioError
        }
        return androidHome
    }
    
    static func getAdbPath() throws -> String {
        if let savedAdbPath = UserDefaults.standard.adbPath, !savedAdbPath.isEmpty {
            return savedAdbPath
        }
        
        do {
            let adbPath = try getAndroidHome() + "/platform-tools/adb"
            UserDefaults.standard.adbPath = adbPath
            return adbPath
        }
        catch {
            throw DeviceError.AndroidStudioError
        }
    }
    
    static func getEmulatorPath() throws -> String {
        if let savedEmulatorPath = UserDefaults.standard.emulatorPath, !savedEmulatorPath.isEmpty {
            return savedEmulatorPath
        }
        
        do {
            let emulatorPath = try getAndroidHome() + "/emulator/emulator"
            UserDefaults.standard.emulatorPath = emulatorPath
            return emulatorPath
        }
        catch {
            throw DeviceError.AndroidStudioError
        }
    }
    
    static func getAdbId(for deviceName: String, adbPath: String) throws -> String {
        let onlineDevices = try shellOut(to: "\(adbPath) devices")
        let splitted = onlineDevices.components(separatedBy: "\n")
        
        for line in splitted {
            let device = line.match("^emulator-[0-9]+")
            guard let deviceId = device.first?.first else {
                continue
            }
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
