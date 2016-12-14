//
//  EGF2Directory.swift
//  EGF2
//
//  Created by LuzanovRoman on 08.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

class EGF2Directory {
    static var main = EGF2Directory()
    
    lazy var appURL: URL = {
        return Bundle.main.resourceURL!
    }()
    
    lazy var cachesURL : URL = {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
    }()
    
    lazy var libraryURL : URL = {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
    }()
    
    lazy var documentsURL : URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }()
    
    func setSkipBackupAttributeForItem(atURL url: URL) {
        if (url as NSURL).checkResourceIsReachableAndReturnError(nil) {
            do {
                try (url as NSURL).setResourceValue(NSNumber(value: true as Bool), forKey: URLResourceKey.isExcludedFromBackupKey)
            }
            catch {
                print("Can't set \(URLResourceKey.isExcludedFromBackupKey) for resource with url = \(url.absoluteString)")
            }
        }
    }
}
