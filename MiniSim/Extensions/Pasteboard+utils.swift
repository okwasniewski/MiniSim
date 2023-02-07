//
//  Pasteboard+utils.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 07/02/2023.
//

import AppKit


extension NSPasteboard {
    func copyToPasteboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)
    }
}
