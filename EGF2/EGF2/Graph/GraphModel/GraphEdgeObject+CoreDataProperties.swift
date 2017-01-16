//
//  GraphEdgeObject+CoreDataProperties.swift
//  EGF2
//
//  Created by LuzanovRoman on 24.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation
import CoreData

extension GraphEdgeObject {

    @nonobjc class func fetchRequest() -> NSFetchRequest<GraphEdgeObject> {
        return NSFetchRequest<GraphEdgeObject>(entityName: "GraphEdgeObject")
    }

    @NSManaged var edge: String?
    @NSManaged var source: String?
    @NSManaged var target: String?
    @NSManaged var index: NSNumber?

}
