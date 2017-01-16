//
//  Data+Additions.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

extension Data {

    init?(jsonObject: Any) {
        if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            self = data
        } else {
            return nil
        }
    }

    func jsonObject() -> Any? {
        return try? JSONSerialization.jsonObject(with: self, options: .mutableContainers)
    }
}
