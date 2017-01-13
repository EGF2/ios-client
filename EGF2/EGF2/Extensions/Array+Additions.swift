//
//  Array+Additions.swift
//  EGF2
//
//  Created by LuzanovRoman on 12.01.17.
//  Copyright © 2017 EigenGraph. All rights reserved.
//

import Foundation

extension Array where Element : Equatable {
    
    mutating func remove(_ object: Element) {
        for i in 0..<count {
            if object == self[i] {
                remove(at: i)
                break
            }
        }
    }
}
