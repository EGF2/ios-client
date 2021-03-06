//
//  EGF2Types.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

public typealias ObjectBlock = (_ object: NSObject?, _ error: NSError?) -> Void
public typealias ObjectsBlock = (_ objects: [NSObject]?, _ count: Int, _ error: NSError?) -> Void
public typealias SearchObjectsBlock = (_ objects: [NSObject]?, _ count: Int, _ last: String?, _ error: NSError?) -> Void
public typealias Completion = (_ result: Any?, _ error: NSError?) -> Void

extension NSNotification.Name {
    public static let EGF2EdgeCreated = NSNotification.Name("EGF2EdgeCreated")
    public static let EGF2EdgeRemoved = NSNotification.Name("EGF2EdgeRemoved")
    public static let EGF2ObjectUpdated = NSNotification.Name("EGF2ObjectUpdated")
    public static let EGF2ObjectDeleted = NSNotification.Name("EGF2ObjectDeleted")
}

extension NSNotification.Name {
    public static let EGF2EdgeLocallyRefreshed = NSNotification.Name("EGF2EdgeLocallyRefreshed")
    public static let EGF2EdgeLocallyPageLoaded = NSNotification.Name("EGF2EdgeLocallyPageLoaded")
}
