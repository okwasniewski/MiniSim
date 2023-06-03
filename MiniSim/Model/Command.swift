//
//  Command.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/05/2023.
//

import Foundation

struct Command: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let command: String
    let icon: String
    let platform: Platform
    let needBootedDevice: Bool
}
