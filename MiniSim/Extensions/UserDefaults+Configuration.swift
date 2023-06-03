//
//  UserDefaults+Configuration.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 05/02/2023.
//

import Foundation

extension UserDefaults {
    public struct Keys {
        static let parameters = "parameters"
        static let commands = "commands"
        static let androidHome = "androidHome"
        static let isOnboardingFinished = "isOnboardingFinished"
    }
    
    @objc dynamic public var androidHome: String? {
        get { string(forKey: Keys.androidHome) }
        set { set(newValue, forKey: Keys.androidHome) }
    }
    
    @objc dynamic public var isOnboardingFinished: Bool {
        get { bool(forKey: Keys.isOnboardingFinished) }
        set { set(newValue, forKey: Keys.isOnboardingFinished) }
    }
    
    public var parameters: Data? {
        get { object(forKey: Keys.parameters) as? Data }
        set { set(newValue, forKey: Keys.parameters) }
    }
    
    public var commands: Data? {
        get { object(forKey: Keys.commands) as? Data }
        set { set(newValue, forKey: Keys.commands) }
    }
}
