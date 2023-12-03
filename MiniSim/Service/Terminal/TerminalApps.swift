//
//  TerminalApps.swift
//  MiniSim
//
//  Created by Gokulakrishnan Subramaniyan on 02/12/23.
//

import Foundation

protocol TerminalApp {
    var name: String { get }
    func getLaunchScript(deviceId: String, logcatCommand: String) -> String
}

struct AppleTerminal: TerminalApp {
    var name: String = "Terminal"
    func getLaunchScript(deviceId: String, logcatCommand: String) -> String {
        """
            tell app \"Terminal\"
                activate
                do script \"\(logcatCommand)\"
            end tell
        """
    }
}

struct ITermTerminal: TerminalApp {
    var name: String = "iTerm"

    func getLaunchScript(deviceId: String, logcatCommand: String) -> String {
        """
            tell app \"iTerm\"
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text \"\(logcatCommand)\"
                end tell
            end tell
        """
    }
}
