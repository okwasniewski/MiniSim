//
//  Platform.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/05/2023.
//

import Foundation

enum Platform: String, Codable {
    case ios
    case android
    case harmony
}

// TODO: Remove this type during migration to CoreData.
enum OldPlatformType: Codable {
    case ios, android
}
