//
//  NSAlert+showError.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/01/2023.
//

import AppKit

extension NSAlert {
    static func showError(message: String) {
        DispatchQueue.main.async {
            let alert = self.init()
            alert.alertStyle = .warning
            var messageText = ""

            if let appName = Bundle.main.appName {
                messageText = "\(appName) - " + String(message.prefix(300))
            }

            alert.messageText = messageText
            alert.icon = NSImage(named: NSImage.cautionName)
            alert.runModal()
        }
    }

    static func showQuestionDialog(title: String, message: String) -> Bool {
        let alert = self.init()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
