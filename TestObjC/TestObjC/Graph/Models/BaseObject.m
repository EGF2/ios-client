//
//  BaseObject.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "BaseObject.h"

@implementation BaseObject

-(NSArray*)requiredFields {
    return @[
        @"modifiedAt",
        @"id",
        @"createdAt"
    ];
}
@end
