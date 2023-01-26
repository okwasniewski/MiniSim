//
//  AppDelegate.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 26/01/2023.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusBar = StatusBarController()
    }
}
