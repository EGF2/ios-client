//
//  Graph.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "Graph.h"
#import "User.h"

@implementation Graph

+ (EGF2Graph *)main {
    static EGF2Graph * mainGraph = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainGraph = [[EGF2Graph alloc] initWithName:@"EGF2"];
        mainGraph.serverURL = [[NSURL alloc] initWithString:@"http://guide.eigengraph.com/v1/"];
        mainGraph.webSocketURL = [[NSURL alloc] initWithString:@"ws://guide.eigengraph.com:980/v1/listen"];
        mainGraph.idsWithModelTypes = @{
                                        @"03": User.self,
                                        @"08": Product.self,
                                        @"33": DesignerRole.self,
                                        @"09": Collection.self,
                                        @"12": Post.self,
                                        @"14": File.self,
                                        @"16": Message.self
                                        };
    });
    return mainGraph;
}

@end
