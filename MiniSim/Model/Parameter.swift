//
//  Parameter.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 12/03/2023.
//

import Foundation

struct Parameter: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var command: String
    var enabled: Bool = true
}
