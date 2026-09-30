import Foundation

enum DeviceConstants {
  static let deviceBootedError = "Unable to boot device in current state: Booted"
  static let derivedDataLocation = "~/Library/Developer/Xcode/DerivedData"

  enum ProcessPaths: String {
    case xcrun = "/usr/bin/xcrun"
    case xcodeSelect = "/usr/bin/xcode-select"
    case open = "/usr/bin/open"
  }

  enum BundleURL: String {
    case emulator = "qemu-system-aarch64"
    case simulator = "Simulator.app"
    case deviceHub = "DeviceHub.app"
  }

  /// Paths relative to the directory returned by `xcode-select -p`.
  enum AppRelativePaths: String {
    case simulatorExecutable =
      "Applications/Simulator.app/Contents/MacOS/Simulator"
    case deviceHub = "../Applications/DeviceHub.app"
  }
}
