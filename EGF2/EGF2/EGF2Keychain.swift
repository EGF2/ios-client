//
//  EGF2Keychain.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

class EGF2Keychain {
    static let main = EGF2Keychain()
    fileprivate let serviceName = Bundle.main.bundleIdentifier!

    fileprivate func query(extraDictionary: [String: AnyObject]) -> [String: AnyObject] {
        let initDictionary: [String: AnyObject] = [
            String(kSecClass): String(kSecClassGenericPassword) as AnyObject,
            String(kSecAttrGeneric): serviceName.data(using: .utf8)! as AnyObject,
            String(kSecAttrService): serviceName as AnyObject
        ]
        return initDictionary + extraDictionary
    }

    fileprivate func checkStatus(status: OSStatus) -> Bool {
        if status == -34018 {
            print("EGF2Keychain error. Looks like Keychain Sharing is disabled. Please enable it in the 'Capabilities' tab.")
        }
        return status == errSecSuccess
    }

    func set(value: String, forKey key: String) {
        guard let data = value.data(using: String.Encoding.utf8) else { return }

        var query = self.query(extraDictionary: [String(kSecAttrAccount): key as AnyObject])

        if self.value(forKey: key) != nil {
            let attributes = [String(kSecValueData): data]
            if !checkStatus(status: SecItemUpdate(query as CFDictionary, attributes as CFDictionary)) {
                print("EGF2Keychain error. Can't update value for key \(key)")
            }
        } else {
            query[String(kSecValueData)] = data as AnyObject
            if !checkStatus(status: SecItemAdd(query as CFDictionary, nil)) {
                print("EGF2Keychain error. Can't save value for key \(key)")
            }
        }
    }

    func value(forKey key: String) -> String? {
        let query = self.query(extraDictionary: [
            String(kSecAttrAccount): key as AnyObject,
            String(kSecMatchLimit): String(kSecMatchLimitOne) as AnyObject,
            String(kSecReturnData): kCFBooleanTrue
        ])
        var result: AnyObject?

        if checkStatus(status: SecItemCopyMatching(query as CFDictionary, &result)) {
            if let data = result as? Data, let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        return nil
    }

    func deleteValue(forKey key: String) {
        let query = self.query(extraDictionary: [String(kSecAttrAccount): key as AnyObject])
        let status = SecItemDelete(query as CFDictionary)

        if status != errSecItemNotFound {
            if !checkStatus(status: status) {
                print("EGF2Keychain error. Can't delete value for key \(key)")
            }
        }
    }
}
