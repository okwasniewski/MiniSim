import AppKit
import Foundation

protocol ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, device: Device, itemName: String) -> Action
}

class AndroidActionFactory: ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, device: Device, itemName: String) -> any Action {
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
      return DeleteAction(device: device)
    case .customCommand:
      return CustomCommandAction(device: device, itemName: itemName)
    case .logcat:
      return LaunchLogCat(device: device)
    }
  }
}

class IOSActionFactory: ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, device: Device, itemName: String) -> any Action {
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
      return DeleteAction(device: device)
    default:
      fatalError("Unhandled action tag: \(tag)")
    }
  }
}

class ActionExecutor {
  private let queue: DispatchQueue

  init(queue: DispatchQueue = DispatchQueue(label: "com.MiniSim.ActionExecutor")) {
    self.queue = queue
  }

  func execute(
    device: Device,
    commandTag: SubMenuItems.Tags,
    itemName: String
  ) {
    let action: Action

    switch device.platform {
    case .android:
      action = AndroidActionFactory.createAction(
        for: commandTag,
        device: device,
        itemName: itemName
      )
    case .ios:
      action = IOSActionFactory.createAction(
        for: commandTag,
        device: device,
        itemName: itemName
      )
    }

    if action.showQuestionDialog() {
      return
    }

    queue.async {
      do {
        try action.execute()
      } catch {
        NSAlert.showError(message: error.localizedDescription)
      }
    }
  }
}
