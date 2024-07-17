import Foundation

extension Thread {
  static func assertMainThread() {
#if DEBUG
    precondition(Thread.isMainThread, "Not on main thread")
#endif
  }

  static func assertBackgroundThread() {
#if DEBUG
    precondition(!Thread.isMainThread, "On main thread")
#endif
  }
}
