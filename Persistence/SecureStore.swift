//
//  SecureStore.swift
//  metamask-ios-sdk
//

import Foundation

public protocol SecureStore {
    func string(for key: String) -> String?
    
    @discardableResult
    func deleteData(for key: String) -> Bool
    
    @discardableResult
    func save(string: String, key: String) -> Bool
}

public struct Keychain: SecureStore {
    private let service: String
    
    public init(service: String = "com.metamask.ios.sdk") {
        self.service = service
    }
    
    public func string(for key: String) -> String? {
        guard
            let data = data(for: key),
            let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }
    
    public func deleteData(for key: String) -> Bool {
        let request = deletionRequestForKey(key)
        let status: OSStatus = SecItemDelete(request)
        return status == errSecSuccess
    }
    
    public func save(string: String, key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, key: key)
    }
    
    // MARK: Helper functions
    
    
    private func data(for key: String) -> Data? {
        let request = requestForKey(key)
        var dataTypeRef: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(request, &dataTypeRef)
        
        switch status {
            case errSecSuccess:
                return dataTypeRef as? Data
            default:
                return nil
        }
    }
    
    @discardableResult
    private func save(data: Data, key: String) -> Bool {
        guard let attributes = attributes(for: data, key: key) else { return false }
        
        let status: OSStatus = SecItemAdd(attributes, nil)
        
        switch status {
            case noErr:
                return true
            case errSecDuplicateItem:
                guard deleteData(for: key) else { return false }
                return save(data: data, key: key)
            default:
                return false
        }
    }
    
    private func requestForKey(_ key: String) -> CFDictionary {
        [
            kSecReturnData: true,
            kSecAttrAccount: key,
            kSecAttrService: service,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
    }
    
    private func deletionRequestForKey(_ key: String) -> CFDictionary {
        [
            kSecAttrAccount: key,
            kSecAttrService: service,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
    }
    
    private func attributes(for data: Data, key: String) -> CFDictionary? {
        [
            kSecValueData: data,
            kSecAttrAccount: key,
            kSecAttrService: service,
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as CFDictionary
    }
}
