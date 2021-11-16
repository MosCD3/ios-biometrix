//
//  Models.swift
//  BiometrX
//
//  Created by Mostafa Gamal on 2021-11-07.
//
import Foundation

struct Credentials {
    var pin: String
}

enum KeychainError: Error {
    case noPin
    case unexpectedPinData
    case unhandledError(status: OSStatus)
}

enum BiometricError: LocalizedError {
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case biometryChanged
    case unknown

    var errorDescription: String? {
        switch self {
        case .authenticationFailed: return "There was a problem verifying your identity."
        case .userCancel: return "You pressed cancel."
        case .userFallback: return "You pressed password."
        case .biometryNotAvailable: return "Face ID/Touch ID is not available."
        case .biometryNotEnrolled: return "Face ID/Touch ID is not set up."
        case .biometryLockout: return "Face ID/Touch ID is locked."
        case .biometryChanged: return "Biometrics changed"
        case .unknown: return "Face ID/Touch ID may not be configured" 
        }
    }
}
