//
//  EGF2Graph+CoreData.swift
//  EGF2
//
//  Created by LuzanovRoman on 09.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation
import CoreData


extension EGF2Graph {
    
    // MARK: Fileprivate
    fileprivate func objects(withName name: String, predicate: NSPredicate?, sortDescriptors:[NSSortDescriptor]? = nil, fetchLimit: Int = 0, completion: @escaping ([NSManagedObject]?) -> Void) {
        let request = NSFetchRequest<NSManagedObject>(entityName: name)
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = fetchLimit
        request.predicate = predicate
        
        let asynchronousRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (asynchronousResult) -> Void in
            DispatchQueue.main.async {
                completion(asynchronousResult.finalResult)
            }
        }
        do {
            try self.container.viewContext.execute(asynchronousRequest)
        } catch {
            print("EGF2Graph fetch error. \(error.localizedDescription)")
            completion(nil)
        }
    }

    // MARK: Object
    func findGraphObject(withId id: String, completion: @escaping (GraphObject?) -> Void) {
        objects(withName: "GraphObject", predicate: NSPredicate(format: "id = %@", id), fetchLimit: 1) { (objects) in
            completion(objects?.first as? GraphObject)
        }
    }
    
    func newGraphObject(withId id: String) -> GraphObject? {
        if let object = NSEntityDescription.insertNewObject(forEntityName: "GraphObject", into: container.viewContext) as? GraphObject {
            object.id = id
            return object
        }
        return nil
    }
    
    func deleteGraphObject(withId id: String, completion: @escaping () -> Void) {
        let predicate = NSPredicate(format: "id = %@", id)
        objects(withName: "GraphObject", predicate: predicate, fetchLimit: 1) { (objects) in
            if let object = objects?.first {
                self.container.viewContext.delete(object)
            }
            completion()
        }
    }
    
    func graphObject(withId id: String, completion: @escaping (GraphObject?) -> Void) {
        findGraphObject(withId: id) { (graphObject) in
            guard let object = graphObject else {
                completion(self.newGraphObject(withId: id))
                return
            }
            completion(object)
        }
    }

    // MARK: Edge
    func findGraphEdge(withSource source: String, edge: String, completion: @escaping (GraphEdge?) -> Void) {
        let predicate = NSPredicate(format: "source = %@ AND edge = %@", source, edge)
        objects(withName: "GraphEdge", predicate: predicate, fetchLimit: 1) { (objects) in
            completion(objects?.first as? GraphEdge)
        }
    }
    
    func newGraphEdge(withSource source: String, edge: String) -> GraphEdge? {
        if let graphEdge = NSEntityDescription.insertNewObject(forEntityName: "GraphEdge", into: container.viewContext) as? GraphEdge {
            graphEdge.source = source
            graphEdge.edge = edge
            return graphEdge
        }
        return nil
    }
    
    func graphEdge(withSource source: String, edge: String, completion: @escaping (GraphEdge?) -> Void) {
        findGraphEdge(withSource: source, edge: edge) { (graphEdge) in
            guard let edgeObject = graphEdge else {
                completion(self.newGraphEdge(withSource: source, edge: edge))
                return
            }
            completion(edgeObject)
        }
    }
    
    // MARK: Edge objects
    func newGraphEdgeObject(withSource source: String, edge: String, target: String, index: Int) -> GraphEdgeObject? {
        if let object = NSEntityDescription.insertNewObject(forEntityName: "GraphEdgeObject", into: container.viewContext) as? GraphEdgeObject {
            object.source = source
            object.target = target
            object.index = NSNumber(value: index)
            object.edge = edge
            return object
        }
        return nil
    }
    
    func findGraphEdgeObjects(withSource source: String, edge: String, completion: @escaping ([GraphEdgeObject]?) -> Void) {
        let predicate = NSPredicate(format: "source = %@ AND edge = %@", source, edge)
        let sortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        objects(withName: "GraphEdgeObject", predicate: predicate, sortDescriptors: [sortDescriptor]) { (objects) in
            completion(objects as? [GraphEdgeObject])
        }
    }
    
    func findGraphEdgeObject(withSource source: String, edge: String, target: String, completion: @escaping (GraphEdgeObject?) -> Void) {
        let predicate = NSPredicate(format: "source = %@ AND edge = %@ AND target = %@", source, edge, target)
        objects(withName: "GraphEdgeObject", predicate: predicate) { (objects) in
            completion(objects?.first as? GraphEdgeObject)
        }
    }
    
    func deleteGraphEdgeObjects(withSource source: String, edge: String, completion: @escaping () -> Void) {
        let predicate = NSPredicate(format: "source = %@ AND edge = %@", source, edge)
        objects(withName: "GraphEdgeObject", predicate: predicate) { (objects) in
            if let theObjects = objects {
                for object in theObjects {
                    self.container.viewContext.delete(object)
                }
            }
            completion()
        }
    }
    
    // MARK: Common methods
    func deleteAllCoreDataObjects() {
        let edgeObjectsRequest = NSBatchDeleteRequest(fetchRequest: GraphEdgeObject.fetchRequest())
        let objectsRequest = NSBatchDeleteRequest(fetchRequest: GraphObject.fetchRequest())
        let edgesRequest = NSBatchDeleteRequest(fetchRequest: GraphEdge.fetchRequest())
        
        do {
            try container.viewContext.execute(edgeObjectsRequest)
            try container.viewContext.execute(objectsRequest)
            try container.viewContext.execute(edgesRequest)
        }
        catch {
            print("EGF2Graph error. Can't clear database. \(error.localizedDescription)")
        }
    }

    func coreDataSave() {
        do {
            try container.viewContext.save()
        }
        catch {
            print("EGF2Graph error. Can't save changes. \(error.localizedDescription)")
        }
    }
}
