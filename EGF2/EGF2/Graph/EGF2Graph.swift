//
//  EGF2Graph.swift
//  EGF2
//
//  Created by LuzanovRoman on 02.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation
import CoreData


public class EGF2Graph: NSObject {
    
    var api = EGF2GraphAPI()
    var account: EGF2Account
    var container: NSPersistentContainer!

    static fileprivate let notTheFirstPageKey = "notTheFirstPage"
    internal var notificationObjects = [String: Any]()
    fileprivate var isInternalRefresh = false
    
    public var maxPageSize = 50
    public var defaultPageSize = 20
    public var isObjectPaginationMode = false
    public var idsWithModelTypes: [String: NSObject.Type] = [:]
    public var showCacheLogs = false
    
    public var serverURL: URL? {
        didSet {
            api.serverURL = serverURL
        }
    }
    
    public var isAuthorized: Bool {
        get {
            return api.authorization?.isEmpty == false
        }
    }
    
    public init?(name: String) {
        guard let theAccount = EGF2Account(name: name) else { return nil }
        account = theAccount
        api.authorization = theAccount.userToken

        guard let bundle = Bundle(identifier: "com.eigengraph.EGF2") else { return nil }
        guard let url = bundle.url(forResource: "Graph", withExtension: "momd") else { return nil }
        guard let model = NSManagedObjectModel(contentsOf: url) else { return nil }
        
        container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("EGF2Graph. An error has occured while loading persistent stores: \(error), \(error.userInfo)")
            }
        })
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataSave), name: .UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataSave), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func objectWith(type: NSObject.Type, dictionary: [String: Any]) -> NSObject {
        let object = type.init()
        object.setProperties(fromDictionary: dictionary)
        return object
    }
    
    // MARK:- Create (update) core data objects and edges from JSON
    // Four methods below call themselves recursive to create all expanded objects and edges
    
    // Update (create) objects from array of dictionaries (one by one)
    fileprivate func updateChildObjects(withDictionaries dictionaries: [[String: Any]], index: Int, completion: @escaping () -> Void) {
        if dictionaries.count > index {
            updateObject(withDictionary: dictionaries[index]) {
                self.updateChildObjects(withDictionaries: dictionaries, index: index + 1, completion: completion)
            }
        }
        else {
            completion()
        }
    }
    // Update (create) edges from array of dictionaries
    fileprivate func merge(edgeDictionary: [String: Any], forSource source: String, withEdge edge: String, completion: @escaping () -> Void) {
        
        guard let results = edgeDictionary["results"] as? [[String: Any]], let count = edgeDictionary["count"] as? Int else {
            completion()
            return
        }
        var isFirstPage = true
        
        if let notTheFirstPageKey = edgeDictionary[EGF2Graph.notTheFirstPageKey] as? Bool {
            isFirstPage = !notTheFirstPageKey
        }
        graphEdge(withSource: source, edge: edge) { (existGraphEdge) in
            guard let graphEdge = existGraphEdge else {
                completion()
                return
            }
            self.findGraphEdgeObjects(withSource: source, edge: edge) { (graphEdgeObjects) in
                
                func updateEdge(withNewIds ids: [String], completion: @escaping () -> Void) {
                    for i in 0..<ids.count {
                        _ = self.newGraphEdgeObject(withSource: source, edge: edge, target: ids[i], index: i)
                    }
                    graphEdge.count = NSNumber(value: count)
                    completion()
                }
                // new - object ids from server
                var new = [String]()
                
                for result in results {
                    guard let id = result["id"] as? String else {
                        completion()
                        return
                    }
                    new.append(id)
                }
                // old - cached objects
                let old = graphEdgeObjects ?? []
                
                if isFirstPage {
                    // old was empty but new contains some data -> create new edges
                    if old.count == 0 && new.count > 0 {
                        updateEdge(withNewIds: new, completion: completion)
                    }
                    // new is equal to old (or contains more objects)
                    else if old.first?.target == new.first && graphEdge.count?.intValue == count {
                        // Append missing objects if needed
                        if new.count > old.count {
                            for i in old.count..<new.count {
                                _ = self.newGraphEdgeObject(withSource: source, edge: edge, target: new[i], index: i)
                            }
                        }
                        completion()
                    }
                    // remove old and add new
                    else {
                        // Has been asking for empty page or edge is empty
                        if new.isEmpty {
                            // Just update the count
                            updateEdge(withNewIds: [], completion: completion)
                        }
                        else {
                            self.deleteGraphEdgeObjects(withSource: source, edge: edge) {
                                updateEdge(withNewIds: new, completion: completion)
                            }
                        }
                    }
                }
                else {
                    // merge cached data with new data (usually just add new data after cached data)
                    if new.count > 0 {
                        var insertIndex = 0
                    
                        while insertIndex < old.count {
                            if old[insertIndex].target != new[0] {
                                insertIndex += 1
                                continue
                            }
                            insertIndex += 1
                            new.removeFirst()
                            
                            for i in insertIndex..<old.count {
                                self.container.viewContext.delete(old[i])
                            }
                            break
                        }
                        let lastIndex = insertIndex + new.count
                        
                        for i in insertIndex..<lastIndex {
                            _ = self.newGraphEdgeObject(withSource: source, edge: edge, target: new[i - insertIndex], index: i)
                        }
                    }
                    graphEdge.count = NSNumber(value: count)
                    completion()
                }
            }
        }
    }
    // Update (create) edges from array of dictionaries (one by one)
    fileprivate func updateChildEdges(withSource source: String, dictionaries: [[String: Any]], index: Int, completion: @escaping () -> Void) {
        if dictionaries.count > index {
            guard let edge = dictionaries[index].first?.key,
                let dictionary = dictionaries[index].first?.value as? [String: Any],
                let results = dictionary["results"] as? [[String: Any]] else {
                    completion()
                    return
            }
            merge(edgeDictionary: dictionary, forSource: source, withEdge: edge) {
                self.updateChildObjects(withDictionaries: results, index: 0) {
                    self.updateChildEdges(withSource: source, dictionaries: dictionaries, index: index + 1, completion: completion)
                }
            }
        }
        else {
            completion()
        }
    }
    // Update (create) object from dictionaries (one by one)
    fileprivate func updateObject(withDictionary dictionary: [String: Any], completion: @escaping () -> Void) {
        guard let id = dictionary["id"] as? String else {
            completion()
            return
        }
        graphObject(withId: id) { (graphObject) in
            guard let object = graphObject else {
                completion()
                return
            }
            var dataDictionary = [String: Any]()
            var childObjects = [[String: Any]]()
            var childEdges = [[String: Any]]()
            
            for (key, value) in dictionary {
                if let obj = value as? [String: Any], let objId = obj["id"] as? String {
                    dataDictionary[key] = objId
                    childObjects.append(obj)
                }
                else if let obj = value as? [String: Any], let _ = obj["results"] as? [Any], let _ = obj["count"] as? Int {
                    childEdges.append([key: value])
                }
                else {
                    dataDictionary[key] = value
                }
            }
            if let data = Data(jsonObject: self.fixedDictionary(dataDictionary)) {
                object.data = data as NSData
            }
            self.updateChildObjects(withDictionaries: childObjects, index: 0) {
                self.updateChildEdges(withSource: id, dictionaries: childEdges, index: 0) {
                    completion()
                }
            }
        }
    }
    
    // MARK:- Create graph object(s) from response
    // Also save response objects to core data
    fileprivate func object(withResponse response: Any?, completion: ObjectBlock?) {
        guard let dictionary = response as? [String: Any], let id = dictionary["id"] as? String else {
            completion?(nil, EGF2Error(code: .wrongJSONObject))
            return
        }
        guard let type = self.objectType(byId: id) else {
            print("EGF2Graph error. Unknown type for object with id: \(id)")
            completion?(nil, EGF2Error(code: .unknownObjectType, reason: "Unknown type for object with id: \(id)"))
            return
        }
        updateObject(withDictionary: dictionary) {
            if let block = completion {
                block(self.objectWith(type: type, dictionary: self.fixedDictionary(dictionary)), nil)
            }
        }
    }
    
    fileprivate func objects(forSource source: String, onEdge edge: String, withResponse response: Any?, completion: ObjectsBlock?) {
        guard let dictionary = response as? [String: Any],
            let dictionaries = dictionary["results"] as? [[String: Any]],
            let count = dictionary["count"] as? Int else {
                completion?(nil, 0, EGF2Error(code: .wrongResponse))
                return
        }
        updateChildEdges(withSource: source, dictionaries: [[edge: dictionary]], index: 0) {
            if completion == nil { return }
            
            var objects = [NSObject]()
            
            for value in dictionaries {
                guard let id = value["id"] as? String else {
                    completion?(nil, 0, EGF2Error(code: .wrongJSONObject))
                    return
                }
                guard let type = self.objectType(byId: id) else {
                    print("EGF2Graph error. Unknown type for object with id: \(id)")
                    completion?(nil, 0, EGF2Error(code: .unknownObjectType, reason: "Unknown type for object with id: \(id)"))
                    return
                }
                objects.append(self.objectWith(type: type, dictionary: self.fixedDictionary(value)))
            }
            completion?(objects, count, nil)
        }
    }
    
    // MARK:- Converts expand string (e.c. "designer{user,admin},cover_image") to dictionary
    fileprivate func expandValues(byStrings strings: [String]) -> [String: Any] {
        var result = [String:Any]()
        
        for string in strings {
            if string.isEmpty { continue }
            
            var subStrings = [String]()
            var indexes = Array<String.Index>()
            var index = string.startIndex
            var level = 0
            
            while index != string.endIndex {
                if string.characters[index] == "{" { level += 1 }
                if string.characters[index] == "}" { level -= 1 }
                if string.characters[index] == "," && level == 0 {
                    var start = string.startIndex
                    let end = index
                    
                    if let last = indexes.last {
                        start = string.index(after: last)
                    }
                    subStrings.append(string.substring(with: start..<end))
                    indexes.append(end)
                }
                index = string.index(after: index)
            }
            if level > 0 {
                print("EGF2Graph warning. Wrong expand string: '\(string)'")
                continue
            }
            if let start = indexes.last, string.index(after: start) != string.endIndex {
                subStrings.append(string.substring(with: string.index(after: start)..<string.endIndex))
            }
            if subStrings.count == 0 {
                if let start = string.range(of: "{")?.lowerBound,
                    let end = string.range(of: "}", options: .backwards, range: nil, locale: nil)?.lowerBound {
                    let property = string.substring(to: start)
                    let nextProperty = string.substring(with: string.index(after: start)..<end)
                    result[property] = expandValues(byStrings: [nextProperty])
                }
                else {
                    result[string] = [:]
                }
            }
            else {
                result += expandValues(byStrings: subStrings)
            }
        }
        return result
    }
    
    // MARK:- Try to create graph object from cache
    // Four methods below try to load core data objects within all sub objects (recursive) according to expand
    // and create objects
    fileprivate func tryLoad(object: NSObject, dictionary: [String: Any], expand: [String: Any], index: DictionaryIndex<String, Any>, completion: @escaping (_ object: NSObject?) -> Void) {
        if expand.count == 0 || expand.endIndex == index {
            completion(object)
            return
        }
        var property = jsonKeyToObjectKey(expand[index].key)
        var preferredCount = defaultPageSize
        
        if let start = property.range(of: "(")?.upperBound, let end = property.range(of: ")", options: .backwards, range: nil, locale: nil)?.lowerBound {
            if let value = Int(property.substring(with: start..<end)) {
                preferredCount = value
            }
            property.removeSubrange(property.index(before: start)..<property.index(after: end))
        }
        guard let childExpand = expand[index].value as? [String: Any] else {
            completion(nil)
            return
        }
        // If expand is for property
        if let propertyId = dictionary[property] as? String {
            findGraphObject(withId: propertyId) { (graphObject) in
                if let childGraphObject = graphObject {
                    self.tryLoad(graphObject: childGraphObject, withExpand: childExpand) { (childObject) in
                        if let theChildObject = childObject {
                            let objectProperty = "\(property)Object"
                            
                            if object.responds(to: Selector(objectProperty)) {
                                object.setValue(theChildObject, forKey: objectProperty)
                            }
                            self.tryLoad(object: object, dictionary: dictionary, expand: expand, index: expand.index(after: index), completion: completion)
                        }
                        else {
                            completion(nil)
                        }
                    }
                }
                else {
                    completion(nil)
                }
            }
        }
        // If expand is for edge
        else {
            guard let source = dictionary["id"] as? String else {
                completion(nil)
                return
            }
            findGraphEdge(withSource: source, edge: property) { (graphEdge) in
                if let edge = graphEdge, let edgeCount = edge.count?.intValue {
                    self.findGraphEdgeObjects(withSource: source, edge: property) { (graphEdgeObjects) in
                        guard let theGraphEdgeObjects = graphEdgeObjects else {
                            completion(nil)
                            return
                        }
                        // If don't have enough cached objects
                        if preferredCount > theGraphEdgeObjects.count && preferredCount < edgeCount {
                            completion(nil)
                            return
                        }
                        if theGraphEdgeObjects.count == 0 {
                            self.tryLoad(object: object, dictionary: dictionary, expand: expand, index: expand.index(after: index), completion: completion)
                        }
                        else {
                            self.tryLoad(graphObjects: [], byGraphEdgeObjects: theGraphEdgeObjects, index: 0) { (graphObjects) in
                                if let theGraphObjects = graphObjects {
                                    self.tryLoad(objects: [], byGraphObjects: theGraphObjects, index: 0, expand: childExpand) { (edgeObjects) in
                                        if let _ = edgeObjects {
                                            self.tryLoad(object: object, dictionary: dictionary, expand: expand, index: expand.index(after: index), completion: completion)
                                        }
                                        else {
                                            completion(nil)
                                        }
                                    }
                                }
                                else {
                                    completion(nil)
                                }
                            }
                        }
                    }
                }
                else {
                    completion(nil)
                }
            }
        }
    }
    
    fileprivate func tryLoad(graphObjects: [GraphObject], byGraphEdgeObjects edgeObjects: [GraphEdgeObject], index: Int, completion: @escaping (_ objects: [GraphObject]?) -> Void) {
        if index == edgeObjects.count {
            completion(graphObjects)
            return
        }
        guard let target = edgeObjects[index].target else {
            completion(nil)
            return
        }
        findGraphObject(withId: target) { (graphObject) in
            if let object = graphObject {
                self.tryLoad(graphObjects: graphObjects + [object], byGraphEdgeObjects: edgeObjects, index: index + 1, completion: completion)
            }
            else {
                completion(nil)
            }
        }
    }
    
    fileprivate func tryLoad(objects: [NSObject], byGraphObjects graphObjects: [GraphObject], index: Int, expand: [String: Any], completion: @escaping (_ objects: [NSObject]?) -> Void) {
        if index == graphObjects.count {
            completion(objects)
            return
        }
        self.tryLoad(graphObject: graphObjects[index], withExpand: expand) { (object) in
            if let newObject = object {
                self.tryLoad(objects: objects + [newObject], byGraphObjects: graphObjects, index: index + 1, expand: expand, completion: completion)
            }
            else {
                completion(nil)
            }
        }
    }
    
    fileprivate func tryLoad(graphObject: GraphObject, withExpand expand: [String: Any], completion: @escaping (_ object: NSObject?) -> Void) {
        guard let data = graphObject.data as? Data, let dictionary = data.jsonObject() as? [String: Any],
            let id = dictionary["id"] as? String, let type = self.objectType(byId: id) else {
                completion(nil)
                return
        }
        let newObject = objectWith(type: type, dictionary: dictionary)
        tryLoad(object: newObject, dictionary: dictionary, expand: expand, index: expand.startIndex, completion: completion)
    }
    
    // MARK:- Operations with graph objects
    public func object(withId id: String, completion: ObjectBlock?) {
        object(withId: id, expand: [], completion: completion)
    }
    
    public func object(withId id: String, expand: [String], completion: ObjectBlock?) {
        findGraphObject(withId: id) { (graphObject) in
            if let theGraphObject = graphObject {
                self.tryLoad(graphObject: theGraphObject, withExpand: self.expandValues(byStrings: expand)) { (object) in
                    if let theObject = object {
                        if self.showCacheLogs {
                            print("EGF2Graph. Getting object with id '\(id)' from cache")
                        }
                        completion?(theObject, nil)
                    }
                    else {
                        self.refreshObject(withId: id, expand: expand, completion: completion)
                    }
                }
            }
            else {
                self.refreshObject(withId: id, expand: expand, completion: completion)
            }
        }
    }
    
    public func refreshObject(withId id: String, completion: ObjectBlock?) {
        refreshObject(withId: id, expand: [], completion: completion)
    }
    
    public func refreshObject(withId id: String, expand: [String], completion: ObjectBlock?) {
        if showCacheLogs {
            print("EGF2Graph. Loading object with id '\(id)' from server")
        }
        api.object(withId: id, parameters: ["expand":expand.joined(separator: ",")]) { (response, error) in
            guard let _ = error else {
                self.object(withResponse: response, completion: completion)
                return
            }
            completion?(nil, error)
        }
    }
    
    public func userObject(withCompletion completion: ObjectBlock?) {
        if let id = self.account.userId {
            object(withId: id, completion: completion)
            return
        }
        api.object(withId: "me", parameters: nil) { (response, error) in
            if let _ = error {
                completion?(nil, error)
                return
            }
            self.object(withResponse: response) { (result, error) in
                if let object = result, let id = object.value(forKey: "id") as? String {
                    self.account.userId = id
                    self.account.save()
                }
                completion?(result, error)
            }
        }
    }

    public func createObject(withParameters parameters: [String: Any], completion: ObjectBlock?) {
        api.createObject(withParameters: parameters) { (response, error) in
            if let _ = error {
                completion?(nil, error)
                return
            }
            self.object(withResponse: response) { (result, error) in
                if let object = result, let id = object.value(forKey: "id") as? String {
                    NotificationCenter.default.post(name: .EGF2ObjectCreated, object: nil, userInfo: [EGF2ObjectIdInfoKey: id])
                }
                completion?(result, error)
            }
        }
    }
    
    public func updateObject(withId id: String, parameters: [String: Any], completion: ObjectBlock?) {
        api.updateObject(withId: id, parameters: parameters) { (response, error) in
            if let _ = error {
                completion?(nil, error)
                return
            }
            self.findGraphObject(withId: id) { (graphObject) in
                guard let object = graphObject else {
                    self.refreshObject(withId: id, completion: completion)
                    return
                }
                guard let data = object.data as? Data, var dictionary = data.jsonObject() as? [String: Any], let type = self.objectType(byId: id) else {
                    print("EGF2Graph error. Core data object with id = '\(id)' conatins invalid data")
                    completion?(nil, EGF2Error(code: .invalidDataInCoreData, reason: "Core data object with id = '\(id)' conatins invalid data"))
                    return
                }
                for (key, value) in self.fixedDictionary(parameters) {
                    dictionary[key] = value
                }
                if let deleteFields = parameters["delete_fields"] as? [String] {
                    for key in deleteFields {
                        dictionary.removeValue(forKey: key)
                    }
                }
                if let data = Data(jsonObject: dictionary) {
                    object.data = data as NSData
                }
                let updatedObject = self.objectWith(type: type, dictionary: dictionary)
                completion?(updatedObject, nil)
                NotificationCenter.default.post(name: .EGF2ObjectUpdated,
                                                object: self.notificationObject(forSource: id),
                                                userInfo: [EGF2ObjectIdInfoKey: id])
            }
        }
    }
    
    public func updateObject(withId id: String, object: NSObject, completion: ObjectBlock?) {
        let selector = Selector(("editableFields"))
        if object.responds(to: selector) {
            guard let editableFields = object.perform(selector).takeUnretainedValue() as? [String] else {
                completion?(nil, EGF2Error(code: .invalidGraphObject, reason: "Function 'editableFields' returns wrong value"))
                return
            }
            var parameters = [String: Any]()
            
            for (key, value) in object.dictionaryByObjectGraph() {
                if editableFields.contains(key) {
                    parameters[key] = value
                }
            }
            updateObject(withId: id, parameters: parameters, completion: completion)
        }
        else {
            completion?(nil, EGF2Error(code: .invalidGraphObject, reason: "Object doesn't have 'editableFields' function"))
        }
    }
    
    public func deleteObject(withId id: String, completion: Completion?) {
        api.deleteObject(withId: id) { (response, error) in
            if let _ = error {
                completion?(nil, error)
                return
            }
            self.deleteGraphObject(withId: id) {
                completion?(nil, nil)
                NotificationCenter.default.post(name: .EGF2ObjectDeleted,
                                                object: self.notificationObject(forSource: id),
                                                userInfo: [EGF2ObjectIdInfoKey: id])
            }
        }
    }
    
    // MARK:- Operations with edges
    public func createObject(withParameters parameters: [String: Any], forSource source: String, onEdge edge: String, completion: ObjectBlock?) {
        api.createObject(withParameters: parameters, forSource: source, onEdge: edge) { (response, error) in
            if let _ = error {
                completion?(nil, error)
                return
            }
            self.object(withResponse: response) { (object, error) in
                if let _ = error {
                    completion?(nil, error)
                    return
                }
                guard let target = object?.value(forKey: "id") as? String else {
                    completion?(nil, error)
                    return
                }
                self.findGraphEdgeObjects(withSource: source, edge: edge) { (graphEdgeObjects) in
                    if let objects = graphEdgeObjects {
                        for i in 0..<objects.count {
                            objects[i].index = NSNumber(value: i + 1)
                        }
                    }
                    _ = self.newGraphEdgeObject(withSource: source, edge: edge, target: target, index: 0)
                    
                    self.graphEdge(withSource: source, edge: edge) { (graphEdge) in
                        if let theGraphEdge = graphEdge {
                            let count = theGraphEdge.count?.intValue ?? 0
                            theGraphEdge.count = NSNumber(value: count + 1)
                        }
                        completion?(object, nil)
                        NotificationCenter.default.post(name: .EGF2ObjectCreated, object: nil, userInfo: [EGF2ObjectIdInfoKey: target])
                        NotificationCenter.default.post(name: .EGF2EdgeCreated,
                                                        object: self.notificationObject(forSource: source, andEdge: edge),
                                                        userInfo: [EGF2ObjectIdInfoKey: source, EGF2EdgeInfoKey: edge, EGF2EdgeObjectIdInfoKey: target])
                    }
                }
            }
        }
    }
    
    public func addObject(withId id: String, forSource source: String, toEdge edge: String, completion: @escaping Completion) {
        api.addObject(withId: id, forSource: source, onEdge: edge) { (response, error) in
            if let _ = error {
                completion(nil, error)
                return
            }
            self.findGraphEdgeObjects(withSource: source, edge: edge) { (graphEdgeObjects) in
                if let objects = graphEdgeObjects {
                    for i in 0..<objects.count {
                        objects[i].index = NSNumber(value: i + 1)
                    }
                }
                _ = self.newGraphEdgeObject(withSource: source, edge: edge, target: id, index: 0)
                
                self.graphEdge(withSource: source, edge: edge) { (graphEdge) in
                    if let theGraphEdge = graphEdge {
                        let count = theGraphEdge.count?.intValue ?? 0
                        theGraphEdge.count = NSNumber(value: count + 1)
                    }
                    completion(nil, nil)
                    NotificationCenter.default.post(name: .EGF2EdgeCreated,
                                                    object: self.notificationObject(forSource: source, andEdge: edge),
                                                    userInfo: [EGF2ObjectIdInfoKey: source, EGF2EdgeInfoKey: edge, EGF2EdgeObjectIdInfoKey: id])
                }
            }
        }
    }
    
    public func deleteObject(withId id: String, forSource source: String, fromEdge edge: String, completion: @escaping Completion) {
        api.deleteObject(withId: id, forSource: source, fromEdge: edge) { (response, error) in
            if let _ = error {
                completion(nil, error)
                return
            }
            self.findGraphEdgeObjects(withSource: source, edge: edge) { (graphEdgeObjects) in
                if let objects = graphEdgeObjects, let graphEdgeObject = objects.first(where: {$0.target == id}) {
                    let index = objects.index(of: graphEdgeObject)! + 1
                    
                    for i in index..<objects.count {
                        objects[i].index = NSNumber(value: i - 1)
                    }
                    self.container.viewContext.delete(graphEdgeObject)
                }
                self.findGraphEdge(withSource: source, edge: edge) { (graphEdge) in
                    if let theGraphEdge = graphEdge, let count = theGraphEdge.count?.intValue {
                        theGraphEdge.count = NSNumber(value: max(count - 1, 0))
                    }
                    completion(nil, nil)
                    NotificationCenter.default.post(name: .EGF2EdgeRemoved,
                                                    object: self.notificationObject(forSource: source, andEdge: edge),
                                                    userInfo: [EGF2ObjectIdInfoKey: source, EGF2EdgeInfoKey: edge, EGF2EdgeObjectIdInfoKey: id])
                }
            }
        }
    }
    
    public func doesObject(withId id: String, existForSource source: String, onEdge edge: String, completion: @escaping (_ isExist: Bool, _ error: NSError?) -> Void) {
        findGraphEdgeObject(withSource: source, edge: edge, target: id) { (graphEdgeObject) in
            if let _ = graphEdgeObject {
                completion(true, nil)
                return
            }
            self.api.object(withId: id, existOnEdge: edge, forSource: source) { (response, error) in
                if let err = error {
                    if let code = err.userInfo["status_code"] as? Int, code == 404 {
                        completion(false, nil)
                    }
                    else {
                        completion(false, error)
                    }
                    return
                }
                completion(true, nil)
            }
        }
    }
    
    public func objects(forSource source: String, edge: String, completion: ObjectsBlock?) {
        objects(forSource: source, edge: edge, after: nil, expand: [], count: -1, completion: completion)
    }
    
    public func objects(forSource source: String, edge: String, after: String?, completion: ObjectsBlock?) {
        objects(forSource: source, edge: edge, after: after, expand: [], count: -1, completion: completion)
    }
    
    public func objects(forSource source: String, edge: String, after: String?, expand: [String], completion: ObjectsBlock?) {
        objects(forSource: source, edge: edge, after: after, expand: expand, count: -1, completion: completion)
    }
    
    public func objects(forSource source: String, edge: String, after: String?, expand: [String], count: Int, completion: ObjectsBlock?) {
        func refreshObjects() {
            isInternalRefresh = true
            self.refreshObjects(forSource: source, edge: edge, after: after, expand: expand, count: count, completion: completion)
        }
        findGraphEdge(withSource: source, edge: edge) { (graphEdge) in
            guard let theGraphEdge = graphEdge, let theGraphEdgeCount = theGraphEdge.count?.intValue else {
                refreshObjects()
                return
            }
            // If cached edge is empty OR If user asks for empty page
            if theGraphEdgeCount == 0 || count == 0 {
                completion?([], theGraphEdgeCount, nil)
                return
            }
            self.findGraphEdgeObjects(withSource: source, edge: edge) { (graphEdgeObjects) in
                guard let theGraphEdgeObjects = graphEdgeObjects else {
                    refreshObjects()
                    return
                }
                // 1. Check if we have enough cached objects
                let preferredCount = count == -1 ? self.defaultPageSize : count
                var firstIndex = 0
                
                // If user sets 'after' then try to find it, otherwise call 'refreshObjects'
                if let afterId = after {
                    if let afterGraphEdgeObject = theGraphEdgeObjects.first(where: {$0.target == afterId}) {
                        firstIndex = theGraphEdgeObjects.index(of: afterGraphEdgeObject)! + 1
                        
                        if firstIndex == theGraphEdgeObjects.count {
                            if theGraphEdgeObjects.count == theGraphEdgeCount {
                                if self.showCacheLogs {
                                    print("EGF2Graph. Getting objects for source = '\(source)' from edge = '\(edge)' from cache")
                                }
                                completion?([], theGraphEdgeCount, nil)
                            }
                            else {
                                refreshObjects()
                            }
                            return
                        }
                    }
                    else {
                        refreshObjects()
                        return
                    }
                }
                // If we haven't downloaded all objects on edge (user may ask more objects then exist)
                if theGraphEdgeObjects.count < theGraphEdgeCount {
                    // If we don't have enough cached objects
                    if theGraphEdgeObjects.count - firstIndex < preferredCount {
                        refreshObjects()
                        return
                    }
                }
                // 2. Try load edge objects with expand
                let lastIndex = min(theGraphEdgeObjects.count, firstIndex + preferredCount)
                let subGraphEdgeObjects = Array(theGraphEdgeObjects[firstIndex..<lastIndex])
                
                self.tryLoad(graphObjects: [], byGraphEdgeObjects: subGraphEdgeObjects, index: 0) { (graphObjects) in
                    if let theGraphObjects = graphObjects {
                        self.tryLoad(objects: [], byGraphObjects: theGraphObjects, index: 0, expand: self.expandValues(byStrings: expand)) { (edgeObjects) in
                            if let theEdgeObjects = edgeObjects {
                                if self.showCacheLogs {
                                    print("EGF2Graph. Getting objects for source = '\(source)' from edge = '\(edge)' from cache")
                                }
                                completion?(theEdgeObjects, theGraphEdgeCount, nil)
                            }
                            else {
                                refreshObjects()
                            }
                        }
                    }
                    else {
                        refreshObjects()
                    }
                }
            }
        }
    }
    
    public func refreshObjects(forSource source: String, edge: String, completion: ObjectsBlock?) {
        refreshObjects(forSource: source, edge: edge, after: nil, expand: [], count: -1, completion: completion)
    }
    
    public func refreshObjects(forSource source: String, edge: String, after: String?, completion: ObjectsBlock?) {
        refreshObjects(forSource: source, edge: edge, after: after, expand: [], count: -1, completion: completion)
    }
    
    public func refreshObjects(forSource source: String, edge: String, after: String?, expand: [String], completion: ObjectsBlock?) {
        refreshObjects(forSource: source, edge: edge, after: after, expand: expand, count: -1, completion: completion)
    }
    
    public func refreshObjects(forSource source: String, edge: String, after: String?, expand: [String], count: Int, completion: ObjectsBlock?) {
        // Who calls the method? User or EGF2 library
        let isManualRefresh = isInternalRefresh == false
        isInternalRefresh = false
        
        // Call internal method
        func internalRefreshObjects() {
            self.internalRefreshObjects(forSource: source, edge: edge, after: after, expand: expand, count: count, isManualRefresh: isManualRefresh, completion: completion)
        }
        guard let afterValue = after else {
            internalRefreshObjects()
            return
        }
        if isObjectPaginationMode {
            internalRefreshObjects()
        }
        // If user sets 'after' and pagination mode is indexed then try to find an index of that graph object
        else {
            findGraphEdgeObjects(withSource: source, edge: edge) { (graphEdgeObjects) in
                guard let theGraphEdgeObjects = graphEdgeObjects else {
                    let reason = "Pagination mode is indexed and there is no any data for edge '\(edge)' with source '\(source)'. But 'after' parameter is set."
                    completion?(nil, 0, EGF2Error(code: .wrongMethodParameter, reason: reason))
                    return
                }
                if let afterGraphEdgeObject = theGraphEdgeObjects.first(where: {$0.target == afterValue}) {
                    let afterIndex = theGraphEdgeObjects.index(of: afterGraphEdgeObject)!
                    self.internalRefreshObjects(forSource: source, edge: edge, after: "\(afterIndex)", expand: expand, count: count, isManualRefresh: isManualRefresh, completion: completion)
                }
                else {
                    let reason = "Can't find object with id '\(afterValue)' for source '\(source)' on edge '\(edge)'"
                    completion?(nil, 0, EGF2Error(code: .wrongMethodParameter, reason: reason))
                }
            }
        }
    }
    
    internal func internalRefreshObjects(forSource source: String, edge: String, after: String?, expand: [String], count: Int, isManualRefresh: Bool, completion: ObjectsBlock?) {
        
        if showCacheLogs {
            print("EGF2Graph. Loading objects for source = '\(source)' from edge = '\(edge)' from server")
        }
        var parameters = [String: Any]()
        
        if let value = after {
            parameters["after"] = value
        }
        if count >= 0 {
            parameters["count"] = count
        }
        if expand.count > 0 {
            parameters["expand"] = expand.joined(separator: ",")
        }
        api.objects(forSource: source, onEdge: edge, parameters: parameters) { (response, error) in
            if let _ = error {
                completion?(nil, 0, error)
                return
            }
            guard var dictionary = response as? [String: Any] else {
                completion?(nil, 0, EGF2Error(code: .wrongResponse))
                return
            }
            if let _ = after {
                dictionary[EGF2Graph.notTheFirstPageKey] = true
            }
            self.objects(forSource: source, onEdge: edge, withResponse: dictionary) { (objects, count, error) in
                if let _ = error {
                    completion?(nil, 0, error)
                }
                else {
                    completion?(objects, count, nil)
                    let object = self.notificationObject(forSource: source, andEdge: edge)
                    let userInfo: [String: Any] = [
                        EGF2ObjectIdInfoKey: source,
                        EGF2EdgeInfoKey: edge,
                        EGF2EdgeObjectsInfoKey: objects!,
                        EGF2EdgeObjectsCountInfoKey: count
                    ]
                    if isManualRefresh && after == nil {
                        NotificationCenter.default.post(name: .EGF2EdgeRefreshed, object: object, userInfo: userInfo)
                    }
                    else {
                        NotificationCenter.default.post(name: .EGF2EdgePageLoaded, object: object, userInfo: userInfo)
                    }
                }
            }
        }
    }
    
    
    // MARK: File operations
    fileprivate func upload(data: Data, forResponse response: [String: Any], completion: @escaping ObjectBlock) {
        guard let id = response["id"] as? String,
            let mimeType = response["mime_type"] as? String,
            let string = response["upload_url"] as? String,
            let url = URL(string: string) else {
                completion(nil, EGF2Error(code: .wrongResponse))
                return
        }
        // Upload file data
        self.api.uploadFile(withData: data, mimeType: mimeType, url: url) { (response, error) in
            if let _ = error {
                completion(nil, error)
                return
            }
            // Set "uploaded" to true
            self.api.updateObject(withId: id, parameters: ["uploaded": true]) { (response, error) in
                if let _ = error {
                    completion(nil, error)
                }
                else {
                    // Get just created file
                    self.object(withId: id, completion: completion)
                }
            }
        }
    }
    
    public func uploadFile(withData data: Data, title: String, mimeType: String, completion: @escaping ObjectBlock) {
        api.createFile(withTitle: title, mimeType: mimeType) { (result, error) in
            if let _ = error {
                completion(nil, error)
            }
            else if let response = result as? [String: Any] {
                self.upload(data: data, forResponse: response, completion: completion)
            }
            else {
                completion(nil, EGF2Error(code: .wrongResponse))
            }
        }
    }
    
    public func uploadImage(withData data: Data, title: String, mimeType: String, kind: String, completion: @escaping ObjectBlock) {
        api.createImage(withTitle: title, mimeType: mimeType, kind: kind) { (result, error) in
            if let _ = error {
                completion(nil, error)
            }
            else if let response = result as? [String: Any] {
                self.upload(data: data, forResponse: response, completion: completion)
            }
            else {
                completion(nil, EGF2Error(code: .wrongResponse))
            }
        }
    }
}
