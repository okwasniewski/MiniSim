//
//  Onboarding.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 29/03/2023.
//

import Foundation
import AppKit
import SwiftUI

class Onboarding: NSObject {
    private let window = NSWindow(contentRect: .zero, styleMask: [.closable, .titled], backing: .buffered, defer: false)
    private lazy var popover = NSPopover()

    override init() {
        super.init()
        window.title = "Welcome to MiniSim!"
        window.delegate = self
        window.contentView = NSHostingView(rootView: OnboardingPager())
        window.isOpaque = false
        window.titlebarAppearsTransparent = true

        initializeListeners()
    }

    private func initializeListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuWillOpen),
            name: .menuWillOpen,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .menuWillOpen, object: nil)
    }

    @objc private func menuWillOpen() {
        if popover.isShown {
            popover.close()
        }
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func showPopOver(button: NSStatusBarButton?) {
        if let button {
            popover.contentViewController = NSHostingController(rootView: ReadyPopOver())
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

extension Onboarding: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if UserDefaults.standard.androidHome == nil {
            let shouldQuit = NSAlert.showQuestionDialog(
                title: "Are you sure?",
                message: "Closing this window will quit MiniSim."
            )
            if !shouldQuit {
                return false
            }
            NSApp.terminate(nil)
        }
        return true
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
