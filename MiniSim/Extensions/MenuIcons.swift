import AppKit
import Foundation

enum MenuImage: String, CaseIterable {
  case iphone
  case ipad
  case box

  var image: NSImage? {
    guard let itemImage = NSImage(named: self.rawValue) else {
      return nil
    }
    itemImage.size = size
    itemImage.isTemplate = true
    return itemImage
  }

  var size: NSSize {
    switch self {
    case .box:
      return NSSize(width: 16.5, height: 15)
    case .ipad:
      return NSSize(width: 19, height: 14)
    case .iphone:
      return NSSize(width: 11, height: 19)
    }
  }
}
