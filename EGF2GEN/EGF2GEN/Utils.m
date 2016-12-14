//
//  Utils.m
//  EGF2GEN
//
//  Created by LuzanovRoman on 17.11.16.
//  Copyright © 2016 eigengraph. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (int)intForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        return 0;
    }
    id value = [dictionary valueForKey:key];

    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
        return [value intValue];
    }
    return 0;
}

+ (bool)boolForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        return NO;
    }
    id value = [dictionary valueForKey:key];
    
    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return NO;
}

+ (NSArray*)arrayForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }
    id value = [dictionary valueForKey:key];
    
    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

+ (NSString*)stringForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }
    id value = [dictionary valueForKey:key];
    
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

+ (NSDictionary*)dictionaryForKey:(NSString*)key inDictionary:(NSDictionary*)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }
    id value = [dictionary valueForKey:key];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

+ (NSString *)jsonKeyToObjC:(NSString *)jsonKey
{
    NSString * objcKey = [jsonKey copy];
    
    NSRange range = [objcKey rangeOfString:@"_"];
    
    while (range.location != NSNotFound) {
        if (range.location + 1 >= objcKey.length) {
            return jsonKey;
        }
        NSString * character = [objcKey substringWithRange:NSMakeRange(range.location + 1, 1)];
        character = [character uppercaseString];
        objcKey = [objcKey stringByReplacingCharactersInRange:NSMakeRange(range.location, 2) withString:character];
        range = [objcKey rangeOfString:@"_"];
    }
    return objcKey;
}

+ (NSString *)uppercaseFirstLetter:(NSString *)string
{
    NSString * first = [string substringToIndex:1];
    NSString * other = [string substringFromIndex:1];
    first = [first uppercaseString];
    return [first stringByAppendingString:other];
}
@end
