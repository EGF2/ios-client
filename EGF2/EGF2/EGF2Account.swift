//
//  EGF2Account.swift
//  EGF2
//
//  Created by LuzanovRoman on 08.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

class EGF2Account {
    fileprivate let name: String
    
    var userId: String?
    var userToken: String?
    
    init?(name: String) {
        self.name = name
        self.load()
    }
    
    fileprivate var userIdKey: String {
        return name + "user_id"
    }
    
    fileprivate var userTokenKey: String {
        return name + "user_token"
    }
    
    fileprivate var fileTokenKey: String {
        return name + "file_token"
    }
    
    fileprivate var accountFileURL: URL {
        return EGF2Directory.main.documentsURL.appendingPathComponent("\(name)_account_data")
    }
    
    fileprivate func load() {
        // If there is no data on the disk we must clear keychain data
        guard let data = try? Data(contentsOf: accountFileURL) else {
            reset()
            return
        }
        // If file contains invalid or empty token we must remove it OR
        // If there is no keychain token we must remove file
        guard let fileToken = String(data: data, encoding: .utf8), !fileToken.isEmpty, let keychainToken = EGF2Keychain.main.value(forKey: fileTokenKey) else {
            try? FileManager.default.removeItem(at: accountFileURL)
            return
        }
        // Tokens do not match
        if fileToken != keychainToken {
            try? FileManager.default.removeItem(at: accountFileURL)
            reset()
            return
        }
        userToken = EGF2Keychain.main.value(forKey: userTokenKey)
        userId = EGF2Keychain.main.value(forKey: userIdKey)
    }
    
    func save() {
        guard let token = userToken else { return }
        
        // Create file token if needed
        if EGF2Keychain.main.value(forKey: fileTokenKey) == nil {
            let newFileToken = UUID().uuidString

            do {
                try newFileToken.data(using: .utf8)?.write(to: accountFileURL)
                EGF2Directory.main.setSkipBackupAttributeForItem(atURL: accountFileURL)
                EGF2Keychain.main.set(value: newFileToken, forKey: fileTokenKey)
            }
            catch {
                print("EGF2Account error. Can't save account data.")
            }
        }
        if let value = userId {
            EGF2Keychain.main.set(value: value, forKey: userIdKey)
        }
        EGF2Keychain.main.set(value: token, forKey: userTokenKey)
    }
    
    func reset() {
        userId = nil
        userToken = nil
        EGF2Keychain.main.deleteValue(forKey: fileTokenKey)
        EGF2Keychain.main.deleteValue(forKey: userTokenKey)
        EGF2Keychain.main.deleteValue(forKey: userIdKey)
        try? FileManager.default.removeItem(at: accountFileURL)
    }
}
