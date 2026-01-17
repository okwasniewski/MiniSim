//
//  DeviceFamily.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 17/01/2026.
//

import Foundation

enum DeviceFamily: String, Codable {
  case iPhone
  case iPad
  case watch
  // swiftlint:disable:next identifier_name
  case tv
  case vision
  case unknown

  var iconName: String {
    switch self {
    case .iPhone:
      return "iphone"
    case .iPad:
      return "ipad.landscape"
    case .watch:
      return "applewatch"
    case .tv:
      return "appletv.fill"
    case .vision:
      return "visionpro"
    case .unknown:
      return "iphone"
    }
  }

  /// Parses `deviceTypeIdentifier` from simctl JSON output.
  /// Example: `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro`
  init(fromDeviceTypeIdentifier identifier: String) {
    if identifier.contains("iPhone") {
      self = .iPhone
    } else if identifier.contains("iPad") {
      self = .iPad
    } else if identifier.contains("Apple-Watch") {
      self = .watch
    } else if identifier.contains("Apple-TV") {
      self = .tv
    } else if identifier.contains("Apple-Vision") {
      self = .vision
    } else {
      self = .unknown
    }
  }
}
