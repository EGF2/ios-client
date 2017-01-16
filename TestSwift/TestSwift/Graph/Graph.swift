//
//  Graph.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation
import EGF2

var Graph: EGF2Graph = {
    let graph = EGF2Graph(name: "EGF2")!
    graph.serverURL = URL(string: "http://guide.eigengraph.com/v1/")
    graph.showCacheLogs = true
    graph.idsWithModelTypes = [
        "03": User.self,
        "08": Product.self,
        "33": DesignerRole.self,
        "09": Collection.self,
        "12": Post.self,
        "06": File.self,
        "16": Message.self
    ]
    return graph
}()
