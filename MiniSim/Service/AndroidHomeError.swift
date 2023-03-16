//
//  AndroidHomeError.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 27/03/2023.
//
import Foundation

enum AndroidHomeError: Error {
    /*
     Throw when path is not found.
     */
    case pathNotFound
    
    /*
     Throw when provided path is not correct.
     */
    case pathNotCorrect
}

extension AndroidHomeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .pathNotFound:
            return NSLocalizedString("Provided path was not found.", comment: "")
        case .pathNotCorrect:
            return NSLocalizedString("Provided path is not correct. Make sure it points to ANDROID_HOME.", comment: "")
        }
    }
}
