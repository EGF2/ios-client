//
//  EGF2Graph+Notifications.swift
//  EGF2
//
//  Created by LuzanovRoman on 29.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

extension EGF2Graph {

    func notificationObject(forSource source: String) -> Any {
        if notificationObjects[source] == nil {
            notificationObjects[source] = NSObject()
        }
        return notificationObjects[source]!
    }

    func notificationObject(forSource source: String, andEdge edge: String) -> Any {
        let key = source + edge
        if notificationObjects[key] == nil {
            notificationObjects[key] = NSObject()
        }
        return notificationObjects[key]!
    }
    
    public func addObserver(_ observer: NSObject, selector aSelector: Selector, name aName: NSNotification.Name, forSources sources: [String]) {
        subscribe(observer: observer, forObjectsWithIds: sources)
        
        for source in sources {
            notificationCenter.addObserver(observer, selector: aSelector, name: aName, object: notificationObject(forSource: source))
        }
    }
    
    public func addObserver(_ observer: NSObject, selector aSelector: Selector, name aName: NSNotification.Name, forSource source: String) {
        subscribe(observer: observer, forObjectWithId: source)
        notificationCenter.addObserver(observer, selector: aSelector, name: aName, object: notificationObject(forSource: source))
    }
    
    public func removeObserver(_ observer: NSObject, name aName: NSNotification.Name, fromSource source: String) {
        unsubscribe(observer: observer, fromObjectWithId: source)
        notificationCenter.removeObserver(observer, name: aName, object: notificationObject(forSource: source))
    }

    public func addObserver(_ observer: NSObject, selector aSelector: Selector, name aName: NSNotification.Name, forSource source: String, andEdge edge: String) {
        subscribe(observer: observer, forSourceWithId: source, andEdge: edge)
        notificationCenter.addObserver(observer, selector: aSelector, name: aName, object: notificationObject(forSource: source, andEdge: edge))
    }
    
    public func removeObserver(_ observer: NSObject, name aName: NSNotification.Name, fromSource source: String, andEdge edge: String) {
        unsubscribe(observer: observer, fromSourceWithId: source, andEdge: edge)
        notificationCenter.removeObserver(observer, name: aName, object: notificationObject(forSource: source, andEdge: edge))
    }
    
    public func removeObserver(_ observer: NSObject) {
        unsubscribe(observer: observer)
        notificationCenter.removeObserver(observer)
    }
}
