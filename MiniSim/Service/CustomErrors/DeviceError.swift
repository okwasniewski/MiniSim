//
//  DeviceError.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 05/02/2023.
//
import Foundation

enum DeviceError: Error {
    // Throw when device was not found
    case deviceNotFound
    
    // Throw when there was an error with xcode command / configuration
    case XCodeError
    
    // Throw when there was an error with Android command / configuration
    case AndroidStudioError

    // Throw in all other cases
    case unexpected(code: Int)
}


extension DeviceError: LocalizedError {
    public var errorDescription: String? {
            switch self {
            case .deviceNotFound:
                return NSLocalizedString(
                    "Selected device was not found, please make sure it's running.",
                    comment: "Simulator not found"
                )
            case .XCodeError:
                return NSLocalizedString(
                    "There was an error with your XCode developer tools command, make sure you have everything set up properly.",
                    comment: "XCode error"
                )
            case .AndroidStudioError:
                return NSLocalizedString("There was an error with your Android Studio configuration, make sure you have everything set up properly. Make sure ANDROID_HOME environment variable is in PATH.", comment: "Android Studio error")
            case .unexpected(_):
                return NSLocalizedString(
                    "An unexpected error occurred.",
                    comment: "Unexpected Error"
                )
            }
        }
}
