//
//  KeyboardShortcuts.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMiniSim = Self("toggleMiniSim", default: .init(.e, modifiers: [.option, .shift]))
}
