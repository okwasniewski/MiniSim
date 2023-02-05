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
    static func getAdbId(for deviceName: String, adbPath: String) -> String?
    static func isAccesibilityOn(deviceId: String, adbPath: String) -> Bool
}

final class ADB: NSObject, ADBProtocol {
    
    // Constants
    private static let defaultPort = 5552
    private static let maxPort = 5682
    private static let portIncrement = 2
    
    static let talkbackOn = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
    static let talkbackOff = "com.android.talkback/com.google.android.marvin.talkback.TalkBackService"
    
    private static func getSourceFileScript(file: String) -> String {
        return """
                file=\(file)
                if [ -f "$file" ]; then
                    source $file
                fi
                """
    }
    
    static func getAdbPath() throws -> String {
        return try shellOut(to: [
            self.getSourceFileScript(file: "~/.zshrc"),
            self.getSourceFileScript(file: "~/.bashrc"),
            "which adb"
        ])
    }
    
    static func getEmulatorPath() throws -> String {
        return try shellOut(to: [
            self.getSourceFileScript(file: "~/.zshrc"),
            self.getSourceFileScript(file: "~/.bashrc"),
            "which emulator"
        ])
    }
    
    static func getAdbId(for deviceName: String, adbPath: String) -> String? {
        for port in stride(from: defaultPort, through: maxPort, by: portIncrement) {
            do  {
                let output = try shellOut(to: "\(adbPath) -s emulator-\(port) emu avd name")
                let splitted = output.components(separatedBy: "\n")
                
                guard let name = splitted.first else { continue }
                
                if deviceName == name.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return "emulator-\(port)"
                }
                
            } catch {
                // Ignore errors, since they are thrown if we can't find emulator
            }
        }
        return nil
    }
    
    static func isAccesibilityOn(deviceId: String, adbPath: String) -> Bool {
        guard let result = try? shellOut(to: ["\(adbPath) -s \(deviceId) shell settings get secure enabled_accessibility_services"]) else { return false }
        
        if result == talkbackOn {
            return true
        }
        
        return false
    }
}
