//
//  KeyStore.swift
//  BiometrX
//
//  Created by Mostafa Gamal on 2021-11-07.
//

import Foundation
import Security
import LocalAuthentication

public enum KeychainStorageError: Error {
    case unhandledError(OSStatus)
    case invalidData
    case data2StringConversionError
}

public enum PasscodeAccessPolicy {
    case relaxed
    case strict
    case withUserPresence
    case applicationPass
    case bioOrApplicationPass
    case biometrySet
    
    
    func keyChainAttribute() -> String {
        switch self {
        case .relaxed, .strict:
            return kSecAttrAccessible as String
        case .withUserPresence, .applicationPass, .bioOrApplicationPass, .biometrySet:
            return kSecAttrAccessControl as String
        }
    }
    
    func keyChainPolicy(password: String)-> Any {
        switch self {
        case .relaxed:
            return kSecAttrAccessibleWhenUnlocked as String
        case .strict:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
        case .withUserPresence:
            return SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .userPresence,
                nil)!
        case .applicationPass:
            return SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .applicationPassword,
                nil)!
        case .bioOrApplicationPass:
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                [.userPresence, .or, .applicationPassword],
                nil) else {
                    print("COULD NOT CREATE THE ACCESS CONTROL FLAGS!!!!!")

                return  PasscodeAccessPolicy.withUserPresence.keyChainPolicy(password: "")
            }
            
            return accessControl
//            //Flags for biometrics
//            var biometryAndPasscodeFlags = SecAccessControlCreateFlags()
//            biometryAndPasscodeFlags.insert(SecAccessControlCreateFlags.biometryCurrentSet)
//            biometryAndPasscodeFlags.insert(SecAccessControlCreateFlags.or)
//            biometryAndPasscodeFlags.insert(SecAccessControlCreateFlags.applicationPassword)
//
//            //flags for password
//            var applicationPasswordFlag = SecAccessControlCreateFlags()
//            applicationPasswordFlag.insert(SecAccessControlCreateFlags.applicationPassword)
//
//            return SecAccessControlCreateWithFlags(
//                nil,
//                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
////                [biometryAndPasscodeFlags, applicationPasswordFlag ],
//                [biometryAndPasscodeFlags],
//                nil)!
        case .biometrySet:
            return SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil)!
            
        }
    }
    
}

class KeyStore {
    let server = "www.ontario.ca"
    
    init(){}
    
    func store(str: String, forKey: String, strictMode: PasscodeAccessPolicy) -> String? {

        let data = str.data(using: .utf8)!
        
        if strictMode == .strict,
           !PhoneSecurityService.shared.checkBiometrics(forPolicy: .deviceOwnerAuthentication, callback: nil) {
            return "Your phone passcode must be set in strict mode!"
        }
        
        if strictMode == .bioOrApplicationPass,
           !PhoneSecurityService.shared.checkBiometrics(forPolicy: .deviceOwnerAuthenticationWithBiometrics, callback: nil) {
            return "Your biometrics must be set in this mode!"
        }
        

        
            
        
        
       
        var addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: server,
                                       kSecAttrAccount as String: forKey,
                                       strictMode.keyChainAttribute(): strictMode.keyChainPolicy(password: str),
                                       kSecValueData as String: data]
        
        //By using LAContext, I can infuse the created pin and use it as the application password
        //instead of letting iOS pop a window that asks for password
        if strictMode == .bioOrApplicationPass || strictMode == .applicationPass {
            let laContext = LAContext()
            laContext.setCredential(data, type: LACredentialType.applicationPassword)
            addquery[kSecUseAuthenticationContext as String] = laContext
        }
        
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { return "Error saving data" }
        
        print("Value saved in keyChain")
        return nil
    }
    
    func getValue(forKey: String) throws -> String? {
        print("KeyChain: getting value for key:\(forKey)")
        let getquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: server,
                                       kSecAttrAccount as String: forKey,
                                       kSecReturnData as String: true,
                                       kSecReturnAttributes as String: true,
                                       kSecMatchLimit as String: kSecMatchLimitOne]
        
        var result: AnyObject?
        
        
        let status = withUnsafeMutablePointer(to: &result){
            SecItemCopyMatching(getquery as CFDictionary, $0)
        }
        
        
        switch status {
        case errSecSuccess:
            
            print("KeyChain: Item found, retrieving value ..")
            
            guard
                let queriedItem = result as? [String: Any],
                let itemData = queriedItem[kSecValueData as String] as? Data,
                let itemString = String(data: itemData, encoding: .utf8)
            else {
                print("KeyChain: Converter error")
                throw KeychainStorageError.data2StringConversionError
            }
            
            return itemString
        case errSecItemNotFound:
            print("KeyChain: Item not found")
            return nil
        default:
            print("KeyChain: Unhandled error:\(KeychainStorageError.unhandledError(status))")
            throw KeychainStorageError.unhandledError(status)
        }
        
    }
    
    public func removeValue(forKey: String) throws {
        let deletequery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: server,
                                       kSecAttrAccount as String: forKey]
        
        let status = SecItemDelete(deletequery as CFDictionary)
        
        if status != errSecItemNotFound && status != errSecSuccess {
            throw KeychainStorageError.unhandledError(status)
        }
    }
    
    
    public func removeAll() throws {
        let deletequery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: server]
        
        let status = SecItemDelete(deletequery as CFDictionary)
        
        if status != errSecItemNotFound && status != errSecSuccess {
            throw KeychainStorageError.unhandledError(status)
        }
    }
    
    
    
    
    static let shared: KeyStore =  KeyStore()
}
