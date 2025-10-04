import AppKit
import Foundation

protocol Action {
  func execute() throws
  func showQuestionDialog() -> Bool
}

extension Action {
  func showQuestionDialog() -> Bool {
    false
  }
}

// MARK: General Actions

class CopyIDAction: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    if let deviceId = device.identifier {
      NSPasteboard.general.copyToPasteboard(text: deviceId)
      MiniSim.showSuccessMessage(title: "Device ID copied to clipboard!", message: deviceId)
    }
  }
}

class CopyNameAction: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    NSPasteboard.general.copyToPasteboard(text: device.name)
    MiniSim.showSuccessMessage(title: "Device name copied to clipboard!", message: device.name)
  }
}

class DeleteAction: Action {
  let device: Device
  let skipConfirmation: Bool

  init(device: Device, skipConfirmation: Bool = false) {
    self.device = device
    self.skipConfirmation = skipConfirmation
  }

  func showQuestionDialog() -> Bool {
    guard !skipConfirmation else { return false }
    return !NSAlert.showQuestionDialog(
      title: "Are you sure?",
      message: "Are you sure you want to delete this device?"
    )
  }

  func execute() throws {
    try self.device.delete()
    MiniSim.showSuccessMessage(title: "Device deleted!", message: self.device.name)
    NotificationCenter.default.post(name: .deviceDeleted, object: nil)
  }
}

class CustomCommandAction: Action {
  let device: Device
  let itemName: String

  init(device: Device, itemName: String) {
    self.device = device
    self.itemName = itemName
  }

  func execute() throws {
    if let command = CustomCommandService.getCustomCommand(platform: .android, commandName: itemName) {
      try CustomCommandService.runCustomCommand(device, command: command)
    }
  }
}

// MARK: Android Actions

class PasteClipboardAction: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    guard let clipboard = NSPasteboard.general.pasteboardItems?.first,
          let text = clipboard.string(forType: .string) else {
      return
    }
    try ADB.sendText(device: device, text: text)
  }
}

class LaunchLogCat: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    try ADB.launchLogCat(device: device)
  }
}

class ColdBootCommand: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    try device.launch(additionalArgs: ["-no-snapshot"])
  }
}

class NoAudioCommand: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    try device.launch(additionalArgs: ["-no-audio"])
  }
}

class ToggleA11yCommand: Action {
  let device: Device

  init(device: Device) {
    self.device = device
  }

  func execute() throws {
    guard let deviceId = device.identifier else {
      return
    }
    ADB.toggleAccesibility(deviceId: deviceId)
  }
}
