//
//  NSAlert+showError.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import AppKit


extension NSAlert {
    static func showError(error: Error) {
        let alert = self.init()
        alert.alertStyle = .warning
        var messageText = error.localizedDescription
        
        if let appName = Bundle.main.appName {
            messageText = "\(appName) - " + messageText
        }
        
        alert.messageText = messageText
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.runModal()
    }
}
