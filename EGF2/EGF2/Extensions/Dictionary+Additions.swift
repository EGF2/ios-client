//
//  Dictionary+Additions.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func joined(separator: String = ":") -> String {
        var result = ""
        
        for (key, value) in self {
            result += "\(key)\(separator)\(value),"
        }
        if !result.isEmpty {
            return result.withoutLastCharacter()
        }
        return result
    }
}

func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

func + <K, V> (left: [K:V], right: [K:V]) -> [K:V] {
    var result = left
    result += right
    return result
}
