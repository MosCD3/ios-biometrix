//
//  KeyStore.swift
//  BiometrX
//
//  Created by Mostafa Gamal on 2021-11-07.
//

import Foundation
import Security

public enum KeychainStorageError: Error {
    case unhandledError(OSStatus)
    case invalidData
    case data2StringConversionError
}


class KeyStore {
    let server = "www.ontario.ca"
    
    init(){}
    
    func store(str: String, forKey: String) -> String? {

        let data = str.data(using: .utf8)!
        let addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: server,
                                       kSecAttrAccount as String: forKey,
                                       kSecValueData as String: data]
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { return "Error saving data" }
        
        print("Value saved in keyChain")
        return nil
    }
    
    func getValue(forKey: String) throws -> String? {
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
            guard
                let queriedItem = result as? [String: Any],
                let itemData = queriedItem[kSecValueData as String] as? Data,
                let itemString = String(data: itemData, encoding: .utf8)
            else {
                throw KeychainStorageError.data2StringConversionError
            }
            
            return itemString
        case errSecItemNotFound:
            return nil
        default:
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
