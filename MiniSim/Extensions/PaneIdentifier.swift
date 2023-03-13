//
//  PaneIdentifier.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import Preferences

extension Settings.PaneIdentifier {
    static let preferences = Self("preferences")
    static let about = Self("about")
    static let devices = Self("devices")
}
