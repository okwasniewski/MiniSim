import Foundation

enum DeviceConstants {
  static let deviceBootedError = "Unable to boot device in current state: Booted"
  static let derivedDataLocation = "~/Library/Developer/Xcode/DerivedData"

  enum ProcessPaths: String {
    case xcrun = "/usr/bin/xcrun"
    case xcodeSelect = "/usr/bin/xcode-select"
  }

  enum BundleURL: String {
    case emulator = "qemu-system-aarch64"
    case simulator = "Simulator.app"
  }
}
