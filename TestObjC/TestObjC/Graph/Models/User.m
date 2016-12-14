//
//  User.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "User.h"

@implementation Address

@end

@implementation UserName

-(NSArray*)requiredFields {
    return @[
        @"use",
        @"given",
        @"family"
    ];
}
@end

@implementation User
- (NSDictionary*)listPropertiesInfo {
    return @{@"addresses": Address.self};
}

-(NSArray*)editableFields {
    return @[
        @"name"
    ];
}

-(NSArray*)requiredFields {
    return [[super requiredFields] arrayByAddingObjectsFromArray: @[
        @"name",
        @"email"
    ]];
}
@end

@implementation Dimension
@end

@implementation Resize

-(NSArray*)requiredFields {
    return @[
             @"url",
             @"dimensions"
             ];
}
@end

@implementation File

-(NSDictionary*)listPropertiesInfo {
    return @{
             @"resizes": Resize.self
    };
}
-(NSArray*)editableFields {
    return @[
             @"title",
             @"mimeType"
             ];
}

-(NSArray*)requiredFields {
    return [[super requiredFields] arrayByAddingObjectsFromArray: @[
        @"url",
        @"mimeType",
        @"user"
    ]];
}
@end

@implementation Post
@end

@implementation DesignerRole
@end

@implementation Collection
@end

@implementation Product
@end

@implementation Message
@end
