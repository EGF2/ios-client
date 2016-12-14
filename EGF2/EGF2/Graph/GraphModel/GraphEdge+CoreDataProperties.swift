//
//  GraphEdge+CoreDataProperties.swift
//  EGF2
//
//  Created by LuzanovRoman on 06.12.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation
import CoreData


extension GraphEdge {

    @nonobjc class func fetchRequest() -> NSFetchRequest<GraphEdge> {
        return NSFetchRequest<GraphEdge>(entityName: "GraphEdge");
    }

    @NSManaged var count: NSNumber?
    @NSManaged var edge: String?
    @NSManaged var source: String?
    @NSManaged var accessedAt: NSDate?
    @NSManaged var cachedAt: NSDate?

}
