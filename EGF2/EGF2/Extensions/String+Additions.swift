//
//  String+Additions.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

var dateFormatterRFC3339: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter
}()

extension String {
    func withoutLastCharacter() -> String {
        if characters.count > 0 {
            return substring(to: index(before: endIndex))
        }
        return self
    }
    
    func toRFC3339Date() -> Date? {
        return dateFormatterRFC3339.date(from: self.uppercased().replacingOccurrences(of: "Z", with: "-0000"))
    }
}
