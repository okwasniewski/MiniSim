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
    static func getTerminal(type: TerminalType) -> TerminalApp
    static func launchTerminal(terminal: TerminalApp, deviceId: String) throws
}

class TerminalService: TerminalServiceProtocol {
    static func getTerminal(type: TerminalType) -> TerminalApp {
        switch type {
        case .terminal:
            return AppleTerminal()
        case .iterm:
            return ITermTerminal()
        }
    }

    static func launchTerminal(terminal: TerminalApp, deviceId: String) throws {
        let logcatCommand = "adb -s \(deviceId) logcat -v color"
        let terminalScript = terminal.getLaunchScript(deviceId: deviceId, logcatCommand: logcatCommand)
        try shellOut(to: "osascript -e '\(terminalScript)'")
    }
}
