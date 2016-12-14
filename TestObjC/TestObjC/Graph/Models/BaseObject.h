//
//  BaseObject.h
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseObject : NSObject
@property NSString *id;
@property NSDate *createdAt;
@property NSDate *deletedAt;
@property NSDate *modifiedAt;

-(NSArray*)requiredFields;
@end
