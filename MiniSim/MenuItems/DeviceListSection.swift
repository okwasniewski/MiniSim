//
//  DeviceListSection.swift
//  MiniSim
//
//  Created by Anton Kolchunov on 11.10.23.
//

import Foundation

enum DeviceListSection: Int, CaseIterable {
    case iOS = 2000
    case android
    
    var title: String {
        switch self {
        case .iOS:
            return NSLocalizedString("iOS Simulator", comment: "")
        case .android:
            return NSLocalizedString("Android Simulator", comment: "")
        }
    }
}
