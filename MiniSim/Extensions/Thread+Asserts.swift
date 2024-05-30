import Foundation

extension Thread {
  static func assertMainThread() {
    precondition(Thread.isMainThread, "Not on main thread")
  }

  static func assertBackgroundThread() {
    precondition(!Thread.isMainThread, "On main thread")
  }
}
