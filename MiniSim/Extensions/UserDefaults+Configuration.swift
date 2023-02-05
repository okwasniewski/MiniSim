//
//  UserDefaults+Configuration.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 05/02/2023.
//

import Foundation

extension UserDefaults {
    public struct Keys {
        static let adbPath = "adbPath"
        static let emulatorPath = "emulatorPath"
    }
    
    public var adbPath: String? {
      get { string(forKey: Keys.adbPath) }
      set { set(newValue, forKey: Keys.adbPath) }
    }
    
    public var emulatorPath: String? {
      get { string(forKey: Keys.emulatorPath) }
      set { set(newValue, forKey: Keys.emulatorPath) }
    }
}
