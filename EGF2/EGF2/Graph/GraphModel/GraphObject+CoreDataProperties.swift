//
//  GraphObject+CoreDataProperties.swift
//  EGF2
//
//  Created by LuzanovRoman on 06.12.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation
import CoreData

extension GraphObject {

    @nonobjc class func fetchRequest() -> NSFetchRequest<GraphObject> {
        return NSFetchRequest<GraphObject>(entityName: "GraphObject")
    }

    @NSManaged var data: NSObject?
    @NSManaged var id: String?
    @NSManaged var accessedAt: NSDate?
    @NSManaged var cachedAt: NSDate?

}
