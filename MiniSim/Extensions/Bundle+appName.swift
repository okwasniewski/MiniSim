//
//  Bundle+appName.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import Foundation

extension Bundle {
    var appName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}
