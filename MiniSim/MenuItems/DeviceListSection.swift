//
//  DeviceListSection.swift
//  MiniSim
//
//  Created by Anton Kolchunov on 11.10.23.
//

import Foundation

enum DeviceListSection: Int, CaseIterable {
    case iOSPhysical = 100
    case iOSVirtual
    case androidPhysical
    case androidVirtual

    var title: String {
        switch self {
        case .iOSPhysical:
            return NSLocalizedString("iOS Devices", comment: "")
        case .iOSVirtual:
            return NSLocalizedString("iOS Simulator", comment: "")
        case .androidVirtual:
            return NSLocalizedString("Android Simulator", comment: "")
        case .androidPhysical:
            return NSLocalizedString("Android Devices", comment: "")
        }
    }
}
