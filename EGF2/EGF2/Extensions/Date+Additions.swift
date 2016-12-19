//
//  Date+Additions.swift
//  EGF2
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

extension Date {

    func toRFC3339String() -> String {
        let string = dateFormatterRFC3339.string(from: self)
        var components = string.components(separatedBy: "+")
        
        if components.count == 2 {
            components.removeLast()
            components.append("Z")
        }
        var result = components.joined()
        
        // Server can't create a vaild date from string '1970-01-01T00:00:00.000Z'
        if result == "1970-01-01T00:00:00.000Z" {
            result = "1970-01-01T00:00:00.001Z"
        }
        return result
    }
}
