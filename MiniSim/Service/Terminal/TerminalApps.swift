//
//  TerminalApps.swift
//  MiniSim
//
//  Created by Gokulakrishnan Subramaniyan on 02/12/23.
//

import AppKit
import Foundation

protocol TerminalApp {
    var bundleIdentifier: String { get }
    var name: String { get }
    func getLaunchScript(command: String) -> String
}

enum Terminal: String, CaseIterable {
    case terminal = "Terminal"
    case iterm = "iTerm"
    case wezterm = "WezTerm"
    case ghostty = "Ghostty"

    var bundleIdentifier: String {
        switch self {
        case .terminal:
            return "com.apple.Terminal"
        case .iterm:
            return "com.googlecode.iterm2"
        case .wezterm:
            return "com.github.wez.wezterm"
        case .ghostty:
            return "com.mitchellh.ghostty"
        }
    }

    func getApplicationURL() -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    func isAvailable() -> Bool {
        getApplicationURL() != nil
    }

    func getAppIcon() -> NSImage? {
        let appIcon = NSWorkspace.shared.icon(forFile: getApplicationURL()?.path ?? "")
        appIcon.size = NSSize(width: 18, height: 18)
        return appIcon
    }
}

struct AppleTerminal: TerminalApp {
    var name: String = "Terminal"
    var bundleIdentifier: String = "com.apple.Terminal"

    func getLaunchScript(command: String) -> String {
        """
            tell app \"Terminal\"
                activate
                do script \"\(command)\"
            end tell
        """
    }
}

struct ITermTerminal: TerminalApp {
    var name: String = "iTerm"
    var bundleIdentifier: String = "com.googlecode.iterm2"

    func getLaunchScript(command: String) -> String {
        """
            tell app \"iTerm\"
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text \"\(command)\"
                end tell
            end tell
        """
    }
}

struct WezTermTerminal: TerminalApp {
    var name: String = "WezTerm"
    var bundleIdentifier: String = "com.github.wez.wezterm"

    func getLaunchScript(command: String) -> String {
        """
            tell application \"wezterm\" to activate
            do shell script \"/Applications/WezTerm.app/Contents/MacOS/wezterm cli spawn \(command)\"
        """
    }
}

struct GhosttyTerminal: TerminalApp {
    var name: String = "Ghostty"
    var bundleIdentifier: String = "com.mitchellh.ghostty"

    func getLaunchScript(command: String) -> String {
        """
            tell application \"Ghostty\" to activate
            do shell script \"/Applications/Ghostty.app/Contents/MacOS/ghostty -e \(command)\"
        """
    }
}
