import AppKit
import Foundation

class ActionExecutor {
  private let queue: DispatchQueue

  init(queue: DispatchQueue = DispatchQueue(label: "com.MiniSim.ActionExecutor")) {
    self.queue = queue
  }

  func execute(
    device: Device,
    commandTag: SubMenuItems.Tags,
    itemName: String,
    skipConfirmation: Bool = false
  ) {
    let action: Action

    switch device.platform {
    case .android:
      action = AndroidActionFactory.createAction(
        for: commandTag,
        device: device,
        itemName: itemName,
        skipConfirmation: skipConfirmation
      )
    case .ios:
      action = IOSActionFactory.createAction(
        for: commandTag,
        device: device,
        itemName: itemName,
        skipConfirmation: skipConfirmation
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
