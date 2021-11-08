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
