import AppKit
import Foundation

protocol ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, device: Device, itemName: String, skipConfirmation: Bool) -> Action
}

class AndroidActionFactory: ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, device: Device, itemName: String, skipConfirmation: Bool = false) -> any Action {
    switch tag {
    case .copyName:
      return CopyNameAction(device: device)
    case .copyID:
      return CopyIDAction(device: device)
    case .coldBoot:
      return ColdBootCommand(device: device)
    case .noAudio:
      return NoAudioCommand(device: device)
    case .toggleA11y:
      return ToggleA11yCommand(device: device)
    case .paste:
      return PasteClipboardAction(device: device)
    case .delete:
      return DeleteAction(device: device, skipConfirmation: skipConfirmation)
    case .customCommand:
      return CustomCommandAction(device: device, itemName: itemName)
    case .logcat:
      return LaunchLogCat(device: device)
    }
  }
}

class IOSActionFactory: ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, device: Device, itemName: String, skipConfirmation: Bool = false) -> any Action {
    switch tag {
    case .copyName:
      return CopyNameAction(device: device)
    case .copyID:
      return CopyIDAction(device: device)
    case .customCommand:
      return CustomCommandAction(device: device, itemName: itemName)
    case .coldBoot:
      return ColdBootCommand(device: device)
    case .delete:
      return DeleteAction(device: device, skipConfirmation: skipConfirmation)
    default:
      fatalError("Unhandled action tag: \(tag)")
    }
  }
}
