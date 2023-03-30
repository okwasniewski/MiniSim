//
//  UNUserNotificationCenter+showNotification.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 30/03/2023.
//

import Foundation
import UserNotifications

extension UNUserNotificationCenter {
    static func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        self.current().add(request)
    }
}

