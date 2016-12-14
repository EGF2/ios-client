//
//  Utils.h
//  EGF2GEN
//
//  Created by LuzanovRoman on 17.11.16.
//  Copyright © 2016 eigengraph. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (int)intForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary;
+ (bool)boolForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary;
+ (NSArray*)arrayForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary;
+ (NSString*)stringForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary;
+ (NSDictionary*)dictionaryForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary;

+ (NSString *)jsonKeyToObjC:(NSString *)jsonKey;
+ (NSString *)uppercaseFirstLetter:(NSString *)string;
@end
