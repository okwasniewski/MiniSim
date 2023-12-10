//
//  CustomCommandError.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 02/06/2023.
//

import Foundation

enum CustomCommandError: Error {
    /*
     Throw when provided command throws an erorr.
     */
    case commandError(errorMessage: String)
}

extension CustomCommandError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .commandError(let errorMessage):
            return NSLocalizedString("Custom Command Error \n", comment: "") + "\n\(errorMessage)"
        }
    }
}
