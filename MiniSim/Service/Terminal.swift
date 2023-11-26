//
//  Terminal.swift
//  MiniSim
//
//  Created by Gokulakrishnan Subramaniyan on 26/11/23.
//

import Foundation
import ShellOut

enum TerminalType: String {
    case terminal = "Terminal"
    case iterm = "iTerm"
}
protocol TerminalServiceProtocol {
    static func getScript(type: TerminalType, deviceId: String) -> String
    static func launchTerminal(type: TerminalType, deviceId: String) throws
}

class TerminalService: TerminalServiceProtocol {
    static func getScript(type: TerminalType, deviceId: String) -> String {
        let logcatCommand = "adb -s \(deviceId) logcat -v color"
        switch type {
        case .terminal:
            return """
                        tell app \"Terminal\"
                            do script \"\(logcatCommand)\"
                        end tell
                    """
        case .iterm:
            return """
                        tell app \"iTerm\"
                            set newWindow to (create window with default profile)
                            tell current session of newWindow
                                write text \"\(logcatCommand)\"
                            end tell
                        end tell
                    """
        default:
            return ""
        }
    }

    static func launchTerminal(type: TerminalType, deviceId: String) throws {
        let script = getScript(type: type, deviceId: deviceId)
        try shellOut(to: "osascript -e '\(script)'")
    }
}
