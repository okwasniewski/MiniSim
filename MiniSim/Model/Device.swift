//
//  Device.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 25/01/2023.
//

struct Device: Hashable {
    var name: String
    var version: String?
    var ID: String?
    var booted: Bool = false
    
    var isAndroid: Bool = false
}
