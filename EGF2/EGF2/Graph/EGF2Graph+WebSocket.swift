//
//  EGF2Graph+WebSocket.swift
//  EGF2
//
//  Created by LuzanovRoman on 12.01.17.
//  Copyright © 2017 EigenGraph. All rights reserved.
//

import Foundation

class EGF2Subscription {
    var isSent = false
    var observerPointers = [UnsafeRawPointer]()
    var isNoObservers: Bool {
        return observerPointers.isEmpty
    }
    
    static func pointer(forObserver observer: NSObject) -> UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passUnretained(observer).toOpaque())
    }
    
    static func observer(fromPointer pointer: UnsafeRawPointer) -> NSObject {
        return Unmanaged<NSObject>.fromOpaque(pointer).takeUnretainedValue()
    }
    
    init(isSent: Bool, observers: [NSObject]) {
        self.isSent = isSent
        self.observerPointers = observers.map( {EGF2Subscription.pointer(forObserver: $0)} )
    }
    
    func add(_ observer: NSObject) {
        let pointer = EGF2Subscription.pointer(forObserver: observer)
        if let _ = observerPointers.first(where: {$0 == pointer}) { return }
        observerPointers.append(EGF2Subscription.pointer(forObserver: observer))
    }
    
    func remove(_ observer: NSObject) {
        let pointer = EGF2Subscription.pointer(forObserver: observer)
        guard let ptr = observerPointers.first(where: {$0 == pointer}) else { return }
        observerPointers.remove(ptr)
    }
    
    func contains(_ observer: NSObject) -> Bool {
        let pointer = EGF2Subscription.pointer(forObserver: observer)
        return observerPointers.first(where: {$0 == pointer}) != nil
    }
}

extension EGF2Graph: WebSocketDelegate {
    
    // MARK: - Private methods
    fileprivate func startPing() {
        if let timer = webSocketPingTimer {
            timer.invalidate()
        }
        webSocketPingTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] (timer) in
            guard let socket = self?.webSocket else { return }
            socket.write(ping: Data())
        }
    }
    
    fileprivate func stopPing() {
        webSocketPingTimer?.invalidate()
        webSocketPingTimer = nil
    }
    
    // Send JSON for subscribe/unsubscribe a specific object
    // Returns false if subscription wasn't sent
    fileprivate func updateSubscription(subscribe: Bool, forObjecWithId id: String) -> Bool {
        guard let socket = webSocket, socket.isConnected else { return false }
        let action = subscribe ? "subscribe" : "unsubscribe"
        guard let data = Data(jsonObject:[action:[["object_id":id]]]) else { return false }
        guard let string = String(data: data, encoding: .utf8) else { return false }
        socket.write(string: string)
        
        if showLogs {
            print("EGF2Graph. Sent json: \(string).")
        }
        return true
    }
    
    // Send JSON for subscribe/unsubscribe a specific edge
    // Returns false if subscription wasn't sent
    fileprivate func updateSubscription(subscribe: Bool, forSourceWithId id: String, andEdge edge: String) -> Bool {
        guard let socket = webSocket, socket.isConnected else { return false}
        let action = subscribe ? "subscribe" : "unsubscribe"
        guard let data = Data(jsonObject:[action:[["edge":["source":id,"name":edge]]]]) else { return false }
        guard let string = String(data: data, encoding: .utf8) else { return false }
        socket.write(string: string)
        
        if showLogs {
            print("EGF2Graph. Sent json: \(string).")
        }
        return true
    }
    
    fileprivate func subscribe(observer: NSObject, key: String, subscribe: () -> Bool) {
        guard let subscription = subscriptions[key] else {
            subscriptions[key] = EGF2Subscription(isSent: subscribe(), observers: [observer])
            return
        }
        // Add new observer (if needed)
        subscription.add(observer)
    }
    
    fileprivate func unsubscribe(observer: NSObject, key: String, unsubscribe: () -> () ) {
        guard let subscription = subscriptions[key] else { return }
        subscription.remove(observer)
        
        if subscription.isNoObservers {
            if subscription.isSent {
                unsubscribe()
            }
            subscriptions[key] = nil
        }
    }
    
    // MARK: - Internal methods
    func subscribe(observer: NSObject, forObjectWithId id: String) {
        subscribe(observer: observer, key: id) { () -> Bool in
            updateSubscription(subscribe: true, forObjecWithId: id)
        }
    }
    
    func subscribe(observer: NSObject, forSourceWithId id: String, andEdge edge: String) {
        subscribe(observer: observer, key: "\(id)|\(edge)") { () -> Bool in
            updateSubscription(subscribe: true, forSourceWithId: id, andEdge: edge)
        }
    }
    
    func unsubscribe(observer: NSObject, fromObjectWithId id: String) {
        unsubscribe(observer: observer, key: id) { 
            _ = updateSubscription(subscribe: false, forObjecWithId: id)
        }
    }

    func unsubscribe(observer: NSObject, fromSourceWithId id: String, andEdge edge: String) {
        unsubscribe(observer: observer, key: "\(id)|\(edge)") {
            _ = updateSubscription(subscribe: false, forSourceWithId: id, andEdge: edge)
        }
    }
    
    func subscribe(observer: NSObject, forObjectsWithIds ids: [String]) {
        var subscribe = [[String: Any]]()
        let isConnected = webSocket?.isConnected ?? false
        
        for id in ids {
            // If there is a subscription just add new observer (if needed)
            if let subscription = subscriptions[id] {
                subscription.add(observer)
            } else {
                // Add a new subscription
                subscriptions[id] = EGF2Subscription(isSent: isConnected, observers: [observer])
                subscribe.append(["object_id":id])
            }
        }
        // If we need to subscribe for the new objects
        if subscribe.count > 0 && isConnected {
            if let data = Data(jsonObject:["subscribe":subscribe]), let string = String(data: data, encoding: .utf8) {
                webSocket?.write(string: string)
                
                if showLogs {
                    print("EGF2Graph. Sent json: \(string).")
                }
            }
        }
    }
    
    // Unsubscribe observer from all subscriptions
    // Send unsubscribe message via websocket if needed
    func unsubscribe(observer: NSObject) {
        var unsubscribe = [[String: Any]]()
        
        for (key, subscription) in subscriptions {
            if !subscription.contains(observer) {
                continue
            }
            subscription.remove(observer)
            
            if !subscription.isNoObservers {
                continue
            }
            if subscription.isSent {
                let components = key.components(separatedBy: "|")
                
                // Just object id
                if components.count == 1 {
                    guard let id = components.first else { return }
                    unsubscribe.append(["object_id":id])
                    // Object id and edge
                } else {
                    guard let id = components.first, let edge = components.last else { return }
                    unsubscribe.append(["edge":["source":id,"name":edge]])
                }
            }
            subscriptions[key] = nil
        }
        if unsubscribe.count > 0 {
            if let data = Data(jsonObject:["unsubscribe":unsubscribe]), let string = String(data: data, encoding: .utf8) {
                webSocket?.write(string: string)
                
                if showLogs {
                    print("EGF2Graph. Sent json: \(string).")
                }
            }
        }
    }
    
    // MARK: -
    func webSocketConnect() {
        guard let url = webSocketURL, let token = account.userToken  else { return }
        
        // Is already have a connected socket?
        if let socket = webSocket, socket.isConnected { return }
        
        // Is already connecting?
        if webSocketIsConnecting { return }
        
        // Create a new socket and connect it
        webSocketIsConnecting = true
        webSocket = WebSocket(url: url)
        webSocket?.headers["Authorization"] = token
        webSocket?.delegate = self
        webSocket?.connect()
    }
    
    func webSocketDisonnect() {
        webSocket?.disconnect()
    }
    
    // MARK:- WebSocketDelegate
    public func websocketDidConnect(socket: WebSocket) {
        webSocketIsConnecting = false
        var subscribe = [[String: Any]]()
        
        for (key, subscription) in subscriptions {
            if !subscription.isSent {
                let components = key.components(separatedBy: "|")
                
                // Just object id
                if components.count == 1 {
                    guard let id = components.first else { return }
                    subscribe.append(["object_id":id])
                // Object id and edge
                } else {
                    guard let id = components.first, let edge = components.last else { return }
                    subscribe.append(["edge":["source":id,"name":edge]])
                }
                subscription.isSent = true
            }
        }
        if subscribe.count > 0 {
            if let data = Data(jsonObject:["subscribe":subscribe]), let string = String(data: data, encoding: .utf8) {
                socket.write(string: string)
                
                if showLogs {
                    print("EGF2Graph. Sent json: \(string).")
                }
            }
        }
        startPing()
        
        if showLogs {
            print("EGF2Graph. Websocket connected to \(socket.currentURL.absoluteString).")
        }
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        webSocketIsConnecting = false
        
        for (_, subscription) in subscriptions {
            subscription.isSent = false
        }
        stopPing()
        
        if showLogs {
            print("EGF2Graph. Websocket disconnected from \(socket.currentURL.absoluteString).")
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        guard let json = text.data(using: .utf8)?.jsonObject() as? [String: Any] else { return }
        guard let method = json["method"] as? String else { return }
        
        if let objectId = json["object"] as? String {
            if method == "PUT" {
                guard let dictionary = json["current"] as? [String: Any] else { return }
                self.internalUpdateObject(withId: objectId, dictionary: dictionary, completion: nil)
            } else if method == "DELETE" {
                self.internalDeleteObject(withId: objectId, completion: nil)
            }
        } else if let edge = json["edge"] as? [String: String], let src = edge["src"], let dst = edge["dst"], let name = edge["name"] {
            if method == "POST" {
                self.internalAddObject(withId: dst, forSource: src, toEdge: name, completion: nil)
            } else if method == "DELETE" {
                self.internalDeleteObject(withId: dst, forSource: src, fromEdge: name, completion: nil)
            }
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: Data) {
        // Nothing here
    }
}
