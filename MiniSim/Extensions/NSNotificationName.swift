//
//  NSNotificationName.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/03/2023.
//

import Foundation

extension NSNotification.Name {
    static let menuWillOpen = NSNotification.Name("menuWillOpen")
    static let menuDidClose = NSNotification.Name("menuDidClose")
    static let commandDidSucceed = NSNotification.Name("commandDidSucceed")
}
