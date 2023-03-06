//
//  AccessibilityElement.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 03/03/2023.
//

import AppKit
import ShellOut

class AccessibilityElement {
    private let underlyingElement: AXUIElement
    
    required init(_ axUIElement: AXUIElement) {
        self.underlyingElement = axUIElement
    }
    
    @discardableResult func performAction(key: String) -> AXError {
        AXUIElementPerformAction(underlyingElement, key as CFString)
    }
    
    func attribute<T>(key: NSAccessibility.Attribute, type: T.Type) -> T? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(underlyingElement, key as CFString, &value)
        
        guard
            result == .success,
            let typedValue = value as? T
        else {
            return nil
        }
        
        return typedValue
    }
    
    func setAttribute(key: String, value: CFTypeRef) {
        AXUIElementSetAttributeValue(underlyingElement, key as CFString, value);
    }
    
    static func forceFocus(pid: pid_t) {
        DispatchQueue.global(qos: .background).async {
            let script = """
                    osascript -e 'tell application "System Events"
                        set frontmost of every process whose unix id is \(pid) to true
                    end tell'
                    """
            _ = try? shellOut(to: script)
        }
    }
    
    static func hasA11yAccess(prompt: Bool = true) -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: prompt]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        return accessEnabled
    }
    
    static func allWindowsForPID(_ pid: pid_t) -> [AccessibilityElement] {
        let app = AccessibilityElement(AXUIElementCreateApplication(pid))
        let windows = app.attribute(key: .windows, type: [AXUIElement].self)
        guard let windows else {
            return []
        }
        
        return windows.map({AccessibilityElement($0)})
    }
}
