//
//  NSObject+Additions.swift
//  EGF2
//
//  Created by LuzanovRoman on 07.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

enum PropertyType {
    case intValue
    case boolValue
    case floatValue
    case doubleValue
    case dateValue
    case dataValue
    case stringValue
    case listValue(cls: AnyClass)
    case objectValue(cls: AnyClass)
}

fileprivate var classesPropertyList = [String: [String: PropertyType]]()
fileprivate var applicationName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String

extension NSObject {

    func propertyList() -> [String: PropertyType] {

        let className = NSStringFromClass(self.classForCoder)

        if let list = classesPropertyList[className] {
            return list
        } else {
            let list = createPropertyList()
            classesPropertyList[className] = list
            return list
        }
    }

    func createPropertyList() -> [String: PropertyType] {
        var properties = [String: PropertyType]()

        // For Objective-C objects try to get information about list properties
        let selector = NSSelectorFromString("listPropertiesInfo")
        var objCProperties = [String: AnyClass]()

        if self.responds(to: selector) {
            if let value = self.perform(selector).takeUnretainedValue() as? [String: AnyClass] {
                objCProperties = value
            }
        }

        // Simple types, object types, (and array types for ObjC objects only)
        var nextClass: AnyClass? = self.classForCoder

        while nextClass != nil && nextClass != NSObject.self {

            var propertyCount: UInt32 = 0
            if let propertyList = class_copyPropertyList(nextClass!, &propertyCount) {

                for i in 0..<propertyCount {
                    guard let property = propertyList[Int(i)] else { continue }
                    guard let cString = property_getName(property) else { continue }
                    guard let propertyName = String(cString: cString, encoding: .utf8) else { continue }

                    var attributeCount: UInt32 = 0
                    if let attributeList = property_copyAttributeList(property, &attributeCount) {

                        for i in 0..<attributeCount {
                            let attribute = attributeList[Int(i)]
                            guard let attributeName = String(cString: attribute.name, encoding: .utf8) else { continue }
                            guard let attributeValue = String(cString: attribute.value, encoding: .utf8) else { continue }

                            if attributeName == "T" {
                                if attributeValue.characters.count == 1 {
                                    if attributeValue.characters.first == "i" || attributeValue.characters.first == "q" {
                                        properties[propertyName] = PropertyType.intValue
                                    } else if attributeValue.characters.first == "c" || attributeValue.characters.first == "B" {
                                        properties[propertyName] = PropertyType.boolValue
                                    } else if attributeValue.characters.first == "f" {
                                        properties[propertyName] = PropertyType.floatValue
                                    } else if attributeValue.characters.first == "d" {
                                        properties[propertyName] = PropertyType.doubleValue
                                    }
                                } else if attributeValue.characters.count > 3 {
                                    let start = attributeValue.index(attributeValue.startIndex, offsetBy: 2)
                                    let end = attributeValue.index(attributeValue.endIndex, offsetBy: -1)
                                    let className = attributeValue.substring(with: start..<end)

                                    if let cls = NSClassFromString(className) {
                                        if cls == NSDate.self {
                                            properties[propertyName] = PropertyType.dateValue
                                        } else if cls == NSData.self {
                                            properties[propertyName] = PropertyType.dataValue
                                        } else if cls == NSString.self {
                                            properties[propertyName] = PropertyType.stringValue
                                        } else if cls == NSArray.self {
                                            if let arrayInstanceClass = objCProperties[propertyName] {
                                                properties[propertyName] = PropertyType.listValue(cls: arrayInstanceClass)
                                            }
                                        } else {
                                            properties[propertyName] = PropertyType.objectValue(cls: cls)
                                        }
                                    }
                                }
                                break
                            }
                        }
                        free(attributeList)
                    }
                }
                free(propertyList)
            }
            nextClass = nextClass?.superclass()
        }

        // Array types for Swift objects only
        var object: NSObject = self

        while true {
            let mirror = Mirror(reflecting: object)

            for property in mirror.children {
                guard let propertyName = property.label, properties[propertyName] == nil else { continue }

                let propertyClass = type(of: property.value)
                let propertyClassName = "\(propertyClass)"

                guard var start = propertyClassName.range(of: "<")?.lowerBound else { continue }
                guard var end = propertyClassName.range(of: ">")?.upperBound else { continue }

                if propertyClassName.substring(to: start) != "Array" { continue }

                start = propertyClassName.index(after: start)
                end = propertyClassName.index(before: end)

                let arrayInstanceClassName = propertyClassName.substring(with: start..<end)

                if let arrayInstanceClass = NSClassFromString("\(applicationName).\(arrayInstanceClassName)") {
                    properties[propertyName] = PropertyType.listValue(cls: arrayInstanceClass)
                }
            }
            guard let superClass = object.superclass as? NSObject.Type else { break }

            if superClass == NSObject.self {
                break
            }
            object = superClass.init()
        }
        return properties
    }

    func setProperties(fromDictionary dictionary: [String: Any?]) {

        let selector = NSSelectorFromString("requiredFields")
        var requiredFields = [String]()

        if self.responds(to: selector) {
            if let value = self.perform(selector).takeUnretainedValue() as? [String] {
                requiredFields = value
            }
        }
        let properties = propertyList()

        for (key, value) in dictionary {
            if let type = properties[key] {

                var propertyValue: Any?

                switch type {
                case .dateValue:
                    propertyValue = (value as? String)?.toRFC3339Date()

                case .dataValue:
                    ()

                case .stringValue:
                    if let objectDictionary = value as? [String: Any], let id = objectDictionary["id"] as? String {
                        propertyValue = id

                        let objectProperty = "\(key)Object"

                        if let property = properties[objectProperty], case .objectValue(let cls) = property, let type = cls as? NSObject.Type {
                            let object = type.init()
                            object.setProperties(fromDictionary: objectDictionary)
                            self.setValue(object, forKey: objectProperty)
                        }
                    } else if let string = value as? String {
                        propertyValue = string
                    }

                case .intValue:
                    propertyValue = value as? Int

                case .boolValue:
                    propertyValue = value as? Bool

                case .floatValue:
                    propertyValue = value as? Float

                case .doubleValue:
                    propertyValue = value as? Double

                case .listValue(let cls):
                    if let type = cls as? NSObject.Type, let objectsDictionary = value as? [[String: Any]] {
                        var objects = [NSObject]()

                        for objectDictionary in objectsDictionary {
                            let object = type.init()
                            object.setProperties(fromDictionary: objectDictionary)
                            objects.append(object)
                        }
                        propertyValue = objects
                    }

                case .objectValue(let cls):
                    if let type = cls as? NSObject.Type, let objectDictionary = value as? [String: Any] {
                        let object = type.init()
                        object.setProperties(fromDictionary: objectDictionary)
                        propertyValue = object
                    }
                }
                // A valid value for the property
                if let v = propertyValue {
                    self.setValue(v, forKey: key)
                }
                // Value has a wrong type
                else if let valueObject = value {
                    print("EGF2Graph warning. Wrong object type '\(valueObject)' for key '\(key)'")
                }
                // Value isn't set (nil) but property is required
                else if requiredFields.contains(key) {
                    print("EGF2Graph warning. Can't parse object  for key '\(key)'")
                }
            }
        }
    }

    func dictionaryByObjectGraph() -> [String: Any] {
        var dictionary = [String: Any]()
        let properties = propertyList()

        for (key, type) in properties {
            guard let value = self.value(forKey: key) else { continue }

            switch type {
            case .intValue:
                dictionary[key] = value as! Int

            case .boolValue:
                dictionary[key] = value as! Bool

            case .floatValue:
                dictionary[key] = value as! Float

            case .doubleValue:
                dictionary[key] = value as! Double

            case .dateValue:
                dictionary[key] = (value as! Date).toRFC3339String()

            case .dataValue:
                ()

            case .stringValue:
                dictionary[key] = value as! String

            case .objectValue:
                dictionary[key] = (value as! NSObject).dictionaryByObjectGraph()

            case .listValue:
                let objects = value as! [NSObject]
                var list = [[String: Any]]()

                for object in objects {
                    list.append(object.dictionaryByObjectGraph())
                }
                dictionary[key] = list
            }
        }
        return dictionary
    }

    public func copyGraphObject() -> Self {
        let type = type(of:self)
        let object = type.init()
        let properties = propertyList()

        for (key, type) in properties {

            guard let value = self.value(forKey: key) else {
                object.setValue(nil, forKey: key)
                continue
            }

            switch type {
            case .dateValue, .dataValue, .stringValue, .intValue, .boolValue, .floatValue, .doubleValue:
                object.setValue(value, forKey: key)

            case .objectValue:
                if let propertyObject = value as? NSObject {
                    object.setValue(propertyObject.copyGraphObject(), forKey: key)
                }

            case .listValue:
                if let objects = value as? [NSObject] {
                    var newObjects = [NSObject]()

                    for object in objects {
                        newObjects.append(object.copyGraphObject())
                    }
                    object.setValue(newObjects, forKey: key)
                }
            }
        }
        return object
    }

    public func isEqual(graphObject: NSObject) -> Bool {
        let properties = propertyList()

        for (key, type) in properties {
            guard let value1 = self.value(forKey: key) else {
                if graphObject.value(forKey: key) != nil {
                    return false
                }
                continue
            }
            guard let value2 = graphObject.value(forKey: key) else {
                return false
            }
            switch type {
            case .intValue:
                guard let v1 = value1 as? Int, let v2 = value2 as? Int, v1 == v2 else { return false }

            case .boolValue:
                guard let v1 = value1 as? Bool, let v2 = value2 as? Bool, v1 == v2 else { return false }

            case .floatValue:
                guard let v1 = value1 as? Float, let v2 = value2 as? Float, v1 == v2 else { return false }

            case .doubleValue:
                guard let v1 = value1 as? Double, let v2 = value2 as? Double, v1 == v2 else { return false }

            case .dateValue:
                guard let v1 = value1 as? Date, let v2 = value2 as? Date, v1 == v2 else { return false }

            case .dataValue:
                guard let v1 = value1 as? Data, let v2 = value2 as? Data, v1 == v2 else { return false }

            case .stringValue:
                guard let v1 = value1 as? String, let v2 = value2 as? String, v1 == v2 else { return false }

            case .objectValue:
                guard let v1 = value1 as? NSObject, let v2 = value2 as? NSObject, v1.isEqual(graphObject: v2) else { return false }

            case .listValue:
                guard let v1 = value1 as? [NSObject], let v2 = value2 as? [NSObject], v1.count == v2.count else { return false }

                for i in 0..<v1.count {
                    if v1[i].isEqual(graphObject: v2[i]) == false {
                        return false
                    }
                }
            }
        }
        return true
    }

    public func changesFrom(graphObject: NSObject) -> [String: Any]? {
        return changesFrom(graphObject: graphObject, level: 0)
    }

    func changesFrom(graphObject: NSObject, level: Int) -> [String: Any]? {
        if level > 0 && !self.isEqual(graphObject: graphObject) {
            return self.dictionaryByObjectGraph()
        }
        var changes = [String: Any]()
        let properties = propertyList()

        for (key, type) in properties {
            guard let value1 = self.value(forKey: key) else {
                if graphObject.value(forKey: key) != nil {
                    changes[key] = nil
                }
                continue
            }
            guard let value2 = graphObject.value(forKey: key) else {
                changes[key] = value1
                continue
            }
            switch type {
            case .intValue:
                guard let v1 = value1 as? Int, let v2 = value2 as? Int, v1 == v2 else { changes[key] = value1; continue }

            case .boolValue:
                guard let v1 = value1 as? Bool, let v2 = value2 as? Bool, v1 == v2 else { changes[key] = value1; continue }

            case .floatValue:
                guard let v1 = value1 as? Float, let v2 = value2 as? Float, v1 == v2 else { changes[key] = value1; continue }

            case .doubleValue:
                guard let v1 = value1 as? Double, let v2 = value2 as? Double, v1 == v2 else { changes[key] = value1; continue }

            case .dateValue:
                guard let v1 = value1 as? Date, let v2 = value2 as? Date, v1 == v2 else { changes[key] = value1; continue }

            case .dataValue:
                guard let v1 = value1 as? Data, let v2 = value2 as? Data, v1 == v2 else { changes[key] = value1; continue }

            case .stringValue:
                guard let v1 = value1 as? String, let v2 = value2 as? String, v1 == v2 else { changes[key] = value1; continue }

            case .objectValue(let cls):
                guard let v1 = value1 as? NSObject else { continue }
                guard let v2 = value2 as? NSObject else {
                    changes[key] = v1.dictionaryByObjectGraph()
                    continue
                }
                if let objectChanges = v1.changesFrom(graphObject: v2, level: level + 1) {
                    changes[key] = objectChanges
                }

            case .listValue(let cls):
                func setListChanges(forObjects objects: [NSObject]) {
                    var list = [[String: Any]]()

                    for object in objects {
                        list.append(object.dictionaryByObjectGraph())
                    }
                    changes[key] = list
                }
                guard let v1 = value1 as? [NSObject] else { continue }
                guard let v2 = value2 as? [NSObject], v1.count == v2.count else {
                    setListChanges(forObjects: v1)
                    continue
                }
                for i in 0..<v1.count {
                    if v1[i].isEqual(graphObject: v2[i]) == false {
                        setListChanges(forObjects: v1)
                        break
                    }
                }
            }
        }
        if changes.count == 0 {
            return nil
        }
        return changes
    }
}
