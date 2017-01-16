//
//  EGF2Graph+Notifications.swift
//  EGF2
//
//  Created by LuzanovRoman on 29.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

extension EGF2Graph {

    public func notificationObject(forSource source: String) -> Any {
        if notificationObjects[source] == nil {
            notificationObjects[source] = NSObject()
        }
        return notificationObjects[source]!
    }

    public func notificationObject(forSource source: String, andEdge edge: String) -> Any {
        let key = source + edge
        if notificationObjects[key] == nil {
            notificationObjects[key] = NSObject()
        }
        return notificationObjects[key]!
    }
}
