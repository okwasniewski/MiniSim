//
//  Terminal.swift
//  MiniSim
//
//  Created by Gokulakrishnan Subramaniyan on 26/11/23.
//

import Foundation
import ShellOut

protocol TerminalServiceProtocol {
    static func getTerminal(type: Terminal) -> TerminalApp
    static func launchTerminal(command: String, terminal: TerminalApp) throws
}

class TerminalService: TerminalServiceProtocol {
    static func getTerminal(type: Terminal) -> TerminalApp {
        switch type {
        case .terminal:
            return AppleTerminal()
        case .iterm:
            return ITermTerminal()
        case .wezterm:
            return WezTermTerminal()
        case .ghostty:
            return GhosttyTerminal()
        }
    }

    private static func getPrefferedTerminal() -> TerminalApp {
        guard let preferedTerminal = Terminal(
          rawValue: UserDefaults.standard.preferedTerminal ?? Terminal.terminal.rawValue
        )
        else { return getTerminal(type: Terminal.terminal) }

        return getTerminal(type: preferedTerminal)
    }

    static func launchTerminal(command: String, terminal: TerminalApp = getPrefferedTerminal()) throws {
        let terminalScript = terminal.getLaunchScript(command: command)
        try shellOut(to: "osascript -e '\(terminalScript)'")
    }
}
