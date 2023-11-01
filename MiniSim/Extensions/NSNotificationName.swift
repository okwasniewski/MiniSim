//
//  NSNotificationName.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/03/2023.
//

import Foundation

extension Notification.Name {
    static let menuWillOpen = Notification.Name("menuWillOpen")
    static let menuDidClose = Notification.Name("menuDidClose")
    static let deviceDeleted = Notification.Name("deviceDeleted")
    static let commandDidSucceed = Notification.Name("commandDidSucceed")
}
