//
//  EGF2Parser.m
//  EGF2GEN
//
//  Created by LuzanovRoman on 17.11.16.
//  Copyright © 2016 eigengraph. All rights reserved.
//

#import "EGF2Parser.h"
#import "Utils.h"
#include <stdlib.h>

// Console
#define PrintString(string) printf("%s\n", [string cStringUsingEncoding:NSUTF8StringEncoding])
#define PrintFormatString(format,...) printf("%s\n", [[NSString stringWithFormat:(format),__VA_ARGS__] cStringUsingEncoding:NSUTF8StringEncoding])
#define InputString() [EGF2Parser inputString]

// Source
#define SetSource(string) [EGF2Parser setSource:string]
#define AS(string) [EGF2Parser appendString:string]
#define FS(format, ...) \
do { \
    NSString * string = [NSString stringWithFormat:(format), ##__VA_ARGS__]; \
    [EGF2Parser appendString:string];\
} while (0)

// Exit
#define ExitWithMessage(message) \
do { \
    PrintString(message);\
    PrintString(@"Program will be completed ...");\
    usleep(3000000);\
    exit(1);\
} while (0)

#define ExitWithFormatMessage(format, ...) \
do { \
    PrintFormatString(format, __VA_ARGS__);\
    PrintString(@"Program will be completed ...");\
    usleep(3000000);\
    exit(1);\
} while (0)


static NSString * parserVersion = @"1.0";
static NSString * configFileName = @"config";
static NSString * configFileExt = @"json";
static NSString * settingsFileName = @"settings";
static NSString * settingsFileExt = @"json";

static NSString * EGF2Name = nil;
static NSString * EGF2Server = nil;
static NSArray * EGF2ExcludedModels = nil;
static NSString * EGF2ModelPreffix = nil;
static BOOL EGF2IsObjectPaginationMode = false;
static int EGF2DefaultPageSize = 0;
static int EGF2MaxPageSize = 0;
static BOOL isObjC = false;

@implementation EGF2Parser

static NSDictionary * json = nil;
static NSMutableString * source = nil;
static NSMutableArray * createdClasses = nil;

+ (NSString *)inputString {
    char characters[100];
    scanf("%99s", characters);
    return [NSString stringWithCString:characters encoding:NSUTF8StringEncoding];
}

+ (void)setSource:(NSMutableString *)string {
    source = string;
}

+ (void)appendString:(NSString *)string {
    [source appendString:string];
}

+ (void)createFile {
    system( "clear" );
    
    createdClasses = [NSMutableArray array];
    
    PrintFormatString(@"EGF2 generator version: %@\n", parserVersion);
    
    // Load settings file
    NSDictionary * dictionary = [self loadFile:settingsFileName extension:settingsFileExt];
    EGF2Name = [Utils stringForKey:@"name" inDictionary:dictionary];
    EGF2Server = [Utils stringForKey:@"server" inDictionary:dictionary];
    EGF2ExcludedModels = [Utils arrayForKey:@"excluded_models" inDictionary:dictionary];
    EGF2ModelPreffix = [Utils stringForKey:@"model_prefix" inDictionary:dictionary];
    
    if (EGF2Name == nil || EGF2Server == nil || EGF2ExcludedModels == nil || EGF2ModelPreffix == nil) {
        ExitWithMessage(@"Settings file is not valid");
    }
    PrintFormatString(@"'%@' file has been loaded", settingsFileName);
    
    // Load config file
    json = [self loadFile:configFileName extension:configFileExt];
    PrintFormatString(@"'%@' file has been loaded", configFileName);
    
    NSDictionary * graph = [Utils dictionaryForKey:@"graph" inDictionary:json];
    NSDictionary * pagination = [Utils dictionaryForKey:@"pagination" inDictionary:graph];
    
    if (pagination) {
        EGF2IsObjectPaginationMode = [[Utils stringForKey:@"pagination_mode" inDictionary:pagination] isEqual:@"object"];
        EGF2DefaultPageSize = [Utils intForKey:@"default_count" inDictionary:pagination];
        EGF2MaxPageSize = [Utils intForKey:@"max_count" inDictionary:pagination];
    }
    else {
        ExitWithMessage(@"\nConfig file is not valid. Pagination section isn't exist.");
    }
    if (EGF2DefaultPageSize == 0 || EGF2MaxPageSize == 0) {
        ExitWithMessage(@"Config file is not valid. Check pagination section.");
    }
    PrintString(@"\nSelect language:");
    PrintString(@"Swift: 1");
    PrintString(@"Obj-C: 2");
    
    NSString * input = InputString();
    
    if ([input isEqualToString:@"1"] || [input isEqualToString:@"2"]) {
        isObjC = [input isEqualToString:@"2"];
        [self generateFiles];
    }
    else {
        ExitWithMessage(@"You must enter '1' or '2'");
    }
}

+ (NSDictionary *)loadFile:(NSString *)fileName extension:(NSString *)extension {
    NSURL * url = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
    NSData * data = [NSData dataWithContentsOfURL:url];
    
    if (data == nil) {
        ExitWithFormatMessage(@"%@.%@ not found", fileName, extension);
    }
    NSError * error;
    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

    if (error != nil) {
        ExitWithFormatMessage(@"%@.%@ is not valid", fileName, extension);
    }
    return dictionary;
    PrintString(@"Settings file has been loaded");
}

+ (NSString *)propertyType:(NSDictionary *)type {
    NSString * value = [Utils stringForKey:@"type" inDictionary:type];
    
    if ([value isEqual:@"string"] || [value isEqual:@"email"]) {
        return isObjC ? @"NSString *" : @": String?";
    }
    if ([value isEqual:@"date"]) {
        return isObjC ? @"NSDate *": @": Date?";
    }
    if ([value isEqual:@"integer"]) {
        return isObjC ? @"NSInteger " : @": Int = 0";
    }
    if ([value isEqual:@"object_id"]) {
        return isObjC ? @"NSString *" : @": String?";
    }
    if ([value isEqual:@"boolean"]) {
        BOOL value = [Utils boolForKey:@"default" inDictionary:type];
        return isObjC ? @"BOOL " : [NSString stringWithFormat:@": Bool = %@", value ? @"true" : @"false"];
    }
    if ([value isEqual:@"array:struct"]) {
        NSString * className = [Utils jsonKeyToObjC:[Utils stringForKey:@"schema" inDictionary:type]];
        
        if (className) {
            className = [EGF2ModelPreffix stringByAppendingString:[Utils uppercaseFirstLetter:className]];
            return isObjC ? [NSString stringWithFormat:@"NSArray <%@ *> *", className] : [NSString stringWithFormat:@" = [%@]()", className];
        }
    }
    if ([value isEqual:@"struct"]) {
        NSString * className = [Utils jsonKeyToObjC:[Utils stringForKey:@"schema" inDictionary:type]];
        
        if (className) {
            if ([className isEqual:@"any"]) {
                return isObjC ? @"NSObject *" : @": NSObject?";
            }
            className = [EGF2ModelPreffix stringByAppendingString:[Utils uppercaseFirstLetter:className]];
            return isObjC ? [NSString stringWithFormat:@"%@ *", className] : [NSString stringWithFormat:@": %@?", className];
        }
    }
    return nil;
}

+ (void)printMethod:(NSString *)methodName returnFields:(NSArray *)fields isOverride:(BOOL)isOverride {
    if (isObjC) {
        if (fields.count > 0) {
            FS(@"-(NSArray*)%@ {\n\treturn %@@[\n%@\n\t]%@;\n}\n",
               methodName,
               isOverride ? [NSString stringWithFormat:@"[[super %@] arrayByAddingObjectsFromArray: ", methodName] : @"",
               [fields componentsJoinedByString:@",\n"],
               isOverride ? @"]" : @"");
        }
        else if (!isOverride) {
            FS(@"-(NSArray*)%@ {\n\treturn @[];\n}\n", methodName);
        }
    }
    else {
        if (fields.count > 0) {
            FS(@"\t%@func %@() -> [String] {\n\t\treturn %@[\n%@\n\t\t]\n\t}\n",
               isOverride ? @"override " : @"",
               methodName,
               isOverride ? [NSString stringWithFormat:@"super.%@() + ", methodName] : @"",
               [fields componentsJoinedByString:@",\n"]);
        }
        else if (!isOverride) {
            FS(@"\tfunc %@() -> [String] {\n\t\treturn []\n\t}\n", methodName);
        }
    }
}

+ (BOOL)isInvalidObjectDictionary:(id)dictionary forKey:(id )key {
    return [EGF2ExcludedModels containsObject:key] ||
    [Utils boolForKey:@"back_end_only" inDictionary:dictionary] ||
    [Utils stringForKey:@"code" inDictionary:dictionary] == nil;
}

+ (void)generateFiles {

    NSString * sourceName = @"EGF2";
    NSString * requiredFieldsMethod = @"requiredFields";
    NSString * editableFieldsMethod = @"editableFields";
    NSMutableArray * classCodes = [NSMutableArray array];
    NSMutableString * swiftPart1 = [NSMutableString string];
    NSMutableString * swiftPart2 = [NSMutableString string];
    NSMutableString * swiftPart3 = [NSMutableString string];
    NSMutableString * objCHPart1 = [NSMutableString string];
    NSMutableString * objCHPart2 = [NSMutableString string];
    NSMutableString * objCHPart3 = [NSMutableString string];
    NSMutableString * objCSPart1 = [NSMutableString string];
    NSMutableString * objCSPart2 = [NSMutableString string];
    NSMutableString * objCSPart3 = [NSMutableString string];
    
    // Add title for source
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.YY"];
    NSString * date = [dateFormatter stringFromDate:[NSDate date]];
    
    if (isObjC) {
        SetSource(objCHPart1);
        AS(@"//\n");
        FS(@"//  %@.h\n", sourceName);
        AS(@"//  EGF2\n");
        AS(@"//\n");
        FS(@"//  Created by EGF2GEN on %@.\n", date);
        AS(@"//  Copyright © 2016 EigenGraph. All rights reserved.\n");
        AS(@"//\n");
        AS(@"\n");
        AS(@"#import <Foundation/Foundation.h>\n");
        AS(@"@import EGF2;\n\n");
        AS(@"@interface Graph : NSObject\n+ (EGF2Graph *)shared;\n@end\n\n");
        
        SetSource(objCSPart1);
        AS(@"//\n");
        FS(@"//  %@.m\n", sourceName);
        AS(@"//  EGF2\n");
        AS(@"//\n");
        FS(@"//  Created by EGF2GEN on %@.\n", date);
        AS(@"//  Copyright © 2016 EigenGraph. All rights reserved.\n");
        AS(@"//\n");
        AS(@"\n");
        FS(@"#import \"%@.h\"\n\n", sourceName);
    }
    else {
        SetSource(swiftPart1);
        AS(@"//\n");
        FS(@"//  %@.swift\n", sourceName);
        AS(@"//  EGF2\n");
        AS(@"//\n");
        FS(@"//  Created by EGF2GEN on %@.\n", date);
        AS(@"//  Copyright © 2016 EigenGraph. All rights reserved.\n");
        AS(@"//\n");
        AS(@"\n");
        AS(@"import Foundation\n");
        AS(@"import EGF2\n\n");
    }
    // Parse models
    NSDictionary * graph = [Utils dictionaryForKey:@"graph" inDictionary:json];
    
    if (!graph) {
        ExitWithMessage(@"Config file is not valid");
    }
    
    
    // Simple objects
    if (isObjC) {
        SetSource(objCHPart2);
        AS(@"// MARK:- Simple objects\n");
        
        SetSource(objCSPart2);
        AS(@"// MARK:- Simple objects\n");
    }
    else {
        SetSource(swiftPart2);
        AS(@"// MARK:- Simple objects\n");
    }
    NSDictionary * customSchemas = [Utils dictionaryForKey:@"custom_schemas" inDictionary:graph];
    [customSchemas enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString * className = [Utils uppercaseFirstLetter:[Utils jsonKeyToObjC:key]];
        NSDictionary * properties = (NSDictionary *)obj;
        NSMutableArray * requiredFields = [NSMutableArray array];
        className = [EGF2ModelPreffix stringByAppendingString:className];
        
        if (isObjC) {
            SetSource(objCHPart2);
            FS(@"@interface %@ : NSObject\n", className);
            
            SetSource(objCSPart2);
            FS(@"@implementation %@\n", className);
        }
        else {
            SetSource(swiftPart2);
            FS(@"class %@: NSObject {\n", className);
        }
        [properties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString * name = [Utils jsonKeyToObjC:key];
            NSString * type = [self propertyType:obj];
            
            if (!type) {
                ExitWithFormatMessage(@"Unknow property type: %@", [Utils stringForKey:@"type" inDictionary:obj]);
            }
            if (isObjC) {
                SetSource(objCHPart2);
                FS(@"@property %@%@;\n", type, name);
            }
            else {
                SetSource(swiftPart2);
                FS(@"\tvar %@%@\n", name, type);
            }
            if (isObjC) {
                [requiredFields addObject:[NSString stringWithFormat:@"\t\t@\"%@\"", name]];
            }
            else {
                [requiredFields addObject:[NSString stringWithFormat:@"\t\t\t\"%@\"", name]];
            }
        }];
        if (isObjC) {
            SetSource(objCHPart2);
            AS(@"@end\n\n");
            
            SetSource(objCSPart2);
            AS(@"\n");
            [self printMethod:requiredFieldsMethod returnFields:requiredFields isOverride:NO];
            AS(@"@end\n\n");
        }
        else {
            SetSource(swiftPart2);
            AS(@"\n");
            [self printMethod:requiredFieldsMethod returnFields:requiredFields isOverride:NO];
            AS(@"}\n\n");
        }
    }];
    
    
    // Base graph object
    if (isObjC) {
        SetSource(objCHPart2);
        AS(@"// MARK:- Base graph object\n");
        FS(@"@interface %@GraphObject: NSObject\n", EGF2ModelPreffix);
        
        SetSource(objCSPart2);
        AS(@"// MARK:- Base graph object\n");
        FS(@"@implementation %@GraphObject\n", EGF2ModelPreffix);
    }
    else {
        SetSource(swiftPart2);
        AS(@"// MARK:- Base graph object\n");
        FS(@"class %@GraphObject: NSObject {\n", EGF2ModelPreffix);
    }
    NSDictionary * commonFields = [Utils dictionaryForKey:@"common_fields" inDictionary:graph];
    NSMutableArray * baseObjectRequiredFields = [NSMutableArray array];
    NSMutableArray * baseObjectEditableFields = [NSMutableArray array];
    [commonFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqual:@"object_type"]) {
            NSString * name = [Utils jsonKeyToObjC:key];
            NSString * type = [self propertyType:obj];
            NSString * mode = [Utils stringForKey:@"edit_mode" inDictionary:obj];
            Boolean required = [Utils boolForKey:@"required" inDictionary:obj];
            
            if ([mode isEqual:@"E"]) {
                if (isObjC) {
                    [baseObjectEditableFields addObject:[NSString stringWithFormat:@"\t\t@\"%@\"", name]];
                }
                else {
                    [baseObjectEditableFields addObject:[NSString stringWithFormat:@"\t\t\t\"%@\"", name]];
                }
            }
            if (required) {
                if (isObjC) {
                    [baseObjectRequiredFields addObject:[NSString stringWithFormat:@"\t\t@\"%@\"", name]];
                }
                else {
                    [baseObjectRequiredFields addObject:[NSString stringWithFormat:@"\t\t\t\"%@\"", name]];
                }
            }
            if (!type) {
                ExitWithFormatMessage(@"Unknow property type: %@", [Utils stringForKey:@"type" inDictionary:obj]);
            }
            if (isObjC) {
                SetSource(objCHPart2);
                FS(@"@property %@%@;\n", type, name);
            }
            else {
                SetSource(swiftPart2);
                FS(@"\tvar %@%@\n", name, type);
            }
        }
    }];
   
            
    if (isObjC) {
        SetSource(objCHPart2);
        AS(@"-(NSArray*)editableFields;\n");
        AS(@"-(NSArray*)requiredFields;\n");
        AS(@"@end\n\n");
        
        SetSource(objCSPart2);
        AS(@"\n");
        [self printMethod:editableFieldsMethod returnFields:baseObjectEditableFields isOverride:NO];
        AS(@"\n");
        [self printMethod:requiredFieldsMethod returnFields:baseObjectRequiredFields isOverride:NO];
        AS(@"@end\n\n");
    }
    else {
        SetSource(swiftPart2);
        AS(@"\n");
        [self printMethod:editableFieldsMethod returnFields:baseObjectEditableFields isOverride:NO];
        AS(@"\n");
        [self printMethod:requiredFieldsMethod returnFields:baseObjectRequiredFields isOverride:NO];
        AS(@"}\n\n");
    }
    
    // Common objects
    if (isObjC) {
        SetSource(objCHPart2);
        AS(@"// MARK:- Common objects\n");
        
        SetSource(objCSPart2);
        AS(@"// MARK:- Common objects\n");
    }
    else {
        SetSource(swiftPart2);
        AS(@"// MARK:- Common objects\n");
    }
    [graph enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([self isInvalidObjectDictionary:obj forKey:key]) {
            return;
        }
        NSMutableString * currentObjCClass = [NSMutableString string];
        NSString * className = [Utils uppercaseFirstLetter:[Utils jsonKeyToObjC:key]];
        NSString * classCode = [Utils stringForKey:@"code" inDictionary:obj];
        NSDictionary * properties = [Utils dictionaryForKey:@"fields" inDictionary:obj];
        NSMutableArray * editableFields = [NSMutableArray array];
        NSMutableArray * requiredFields = [NSMutableArray array];
        className = [EGF2ModelPreffix stringByAppendingString:className];
        
        [createdClasses addObject:className];
        
        if (isObjC) {
            [classCodes addObject:[NSString stringWithFormat:@"\n\t\t\t@\"%@\": %@.self", classCode, className]];
        }
        else {
            [classCodes addObject:[NSString stringWithFormat:@"\n\t\t\"%@\": %@.self", classCode, className]];
        }
        if (isObjC) {
            SetSource(currentObjCClass);
            FS(@"@interface %@ : %@GraphObject\n", className, EGF2ModelPreffix);
            
            SetSource(objCSPart2);
            FS(@"@implementation %@\n", className);
        }
        else {
            SetSource(swiftPart2);
            FS(@"class %@: %@GraphObject {\n", className, EGF2ModelPreffix);
        }
        NSMutableArray * listProperties = [NSMutableArray array];
        [properties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString * name = [Utils jsonKeyToObjC:key];
            NSString * type = [self propertyType:obj];
            NSString * mode = [Utils stringForKey:@"edit_mode" inDictionary:obj];
            Boolean required = [Utils boolForKey:@"required" inDictionary:obj];
            
            if (!type) {
                *stop = true;
                return;
                ExitWithFormatMessage(@"Unknow property type: %@", [Utils stringForKey:@"type" inDictionary:obj]);
            }
            if (isObjC) {
                if ([[Utils stringForKey:@"type" inDictionary:obj] hasPrefix:@"array:"] && [Utils stringForKey:@"schema" inDictionary:obj]) {
                    NSString * objectType = [Utils stringForKey:@"schema" inDictionary:obj];
                    objectType = [Utils uppercaseFirstLetter:[Utils jsonKeyToObjC:objectType]];
                    objectType = [EGF2ModelPreffix stringByAppendingString:objectType];
                    [listProperties addObject:[NSString stringWithFormat:@"\t\t@\"%@\": %@.self", name, objectType]];
                }
            }
            
            if ([mode isEqual:@"E"]) {
                if (isObjC) {
                    [editableFields addObject:[NSString stringWithFormat:@"\t\t@\"%@\"", name]];
                }
                else {
                    [editableFields addObject:[NSString stringWithFormat:@"\t\t\t\"%@\"", name]];
                }
            }
            if (required) {
                if (isObjC) {
                    [requiredFields addObject:[NSString stringWithFormat:@"\t\t@\"%@\"", name]];
                }
                else {
                    [requiredFields addObject:[NSString stringWithFormat:@"\t\t\t\"%@\"", name]];
                }
            }
            if (isObjC) {
                SetSource(currentObjCClass);
                FS(@"@property %@%@;\n", type, name);
            }
            else {
                SetSource(swiftPart2);
                FS(@"\tvar %@%@\n", name, type);
            }
            if ([[Utils stringForKey:@"type" inDictionary:obj] isEqual:@"object_id"]) {
                NSArray * objectTypes = [Utils arrayForKey:@"object_types" inDictionary:obj];
                
                BOOL isValidObject = true;
                
                for (NSString * objectType in objectTypes) {
                    NSDictionary * objectTypeDictionary = [Utils dictionaryForKey:objectType inDictionary:graph];
                    if (objectTypeDictionary && [self isInvalidObjectDictionary:objectTypeDictionary forKey:objectType]) {
                        isValidObject = false;
                        break;
                    }
                }
                if (isValidObject) {
                    if (objectTypes.count == 1) {
                        NSString * objectType = [objectTypes firstObject];
                        objectType = [EGF2ModelPreffix stringByAppendingString:[Utils jsonKeyToObjC:[Utils uppercaseFirstLetter:objectType]]];
                        
                        if (isObjC) {
                            if (![createdClasses containsObject:objectType]) {
                                [currentObjCClass  insertString:[NSMutableString stringWithFormat:@"@class %@;\n", objectType]  atIndex:0];
                            }
                            SetSource(currentObjCClass);
                            FS(@"@property %@ *%@Object;\n", objectType, name);
                        }
                        else {
                            SetSource(swiftPart2);
                            FS(@"\tvar %@Object: %@?\n", name, objectType);
                        }
                    }
                    else if (objectTypes.count > 1) {
                        if (isObjC) {
                            SetSource(currentObjCClass);
                            FS(@"@property NSObject* %@Object;\n", name);
                        }
                        else {
                            SetSource(swiftPart2);
                            FS(@"\tvar %@Object: NSObject?\n", name);
                        }
                    }
                }
            }
        }];
        
        if (isObjC) {
            SetSource(objCSPart2);
            AS(@"\n");
            
            if (listProperties.count > 0) {
                FS(@"-(NSDictionary*)listPropertiesInfo {\n\treturn @{\n%@\n\t};\n}\n\n", [listProperties componentsJoinedByString:@",\n"]);
            }
            [self printMethod:editableFieldsMethod returnFields:editableFields isOverride:YES];
            AS(@"\n");
            [self printMethod:requiredFieldsMethod returnFields:requiredFields isOverride:YES];
        }
        else {
            SetSource(swiftPart2);
            AS(@"\n");
            [self printMethod:editableFieldsMethod returnFields:editableFields isOverride:YES];
            AS(@"\n");
            [self printMethod:requiredFieldsMethod returnFields:requiredFields isOverride:YES];
        }
        if (isObjC) {
            SetSource(currentObjCClass);
            AS(@"@end\n\n");
            
            SetSource(objCSPart2);
            AS(@"@end\n\n");
        }
        else {
            SetSource(swiftPart2);
            AS(@"}\n\n");
        }
        [objCHPart2 appendString:currentObjCClass];
    }];
    
    
    [classCodes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare: obj2];
    }];
    
    
    // Main graph instance
    if (isObjC) {
        SetSource(objCSPart3);
        AS(@"@implementation Graph\n\n");
    FS(@"+ (EGF2Graph *)shared {\n\
    static EGF2Graph * sharedGraph = nil;\n\
    static dispatch_once_t onceToken;\n\
    dispatch_once(&onceToken, ^{\n\
        sharedGraph = [[EGF2Graph alloc] initWithName:@\"%@\"];\n\
        sharedGraph.serverURL = [[NSURL alloc] initWithString:@\"%@\"];\n\
        sharedGraph.maxPageSize = %i;\n\
        sharedGraph.defaultPageSize = %i;\n\
        sharedGraph.isObjectPaginationMode = %@;\n\
        sharedGraph.idsWithModelTypes = @{%@\n\t\t};\n\
    });\n\
    return sharedGraph;\n}\n", EGF2Name, EGF2Server, EGF2MaxPageSize, EGF2DefaultPageSize, EGF2IsObjectPaginationMode ? @"true" : @"false", [classCodes componentsJoinedByString:@","]);
        AS(@"@end\n\n");
    }
    else {
    SetSource(swiftPart3);
    FS(@"var Graph: EGF2Graph = {\n\
    let graph = EGF2Graph(name: \"%@\")!\n\
    graph.serverURL = URL(string: \"%@\")\n\
    graph.maxPageSize = %i\n\
    graph.defaultPageSize = %i\n\
    graph.isObjectPaginationMode = %@;\n\
    graph.idsWithModelTypes = [%@\n\t]\n\
    return graph\n}()\n\n", EGF2Name, EGF2Server, EGF2MaxPageSize, EGF2DefaultPageSize, EGF2IsObjectPaginationMode ? @"true" : @"false", [classCodes componentsJoinedByString:@","]);
    }
    
    PrintString(@"");
    
    // Save file
    if (isObjC) {
        NSString * fullSource = [NSString stringWithFormat:@"%@%@%@", objCHPart1, objCHPart2, objCHPart3];
        NSData * fileData = [fullSource dataUsingEncoding:NSUTF8StringEncoding];
        NSURL * fileURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.h",sourceName]];
        
        if ([fileData writeToURL:fileURL atomically:YES] == NO) {
            ExitWithMessage(@"Can't save header file");
        }
        PrintFormatString(@"'%@.h' has been successfully generated!", sourceName);
        
        fullSource = [NSString stringWithFormat:@"%@%@%@", objCSPart1, objCSPart3, objCSPart2];
        fileData = [fullSource dataUsingEncoding:NSUTF8StringEncoding];
        fileURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.m",sourceName]];
        
        if ([fileData writeToURL:fileURL atomically:YES] == NO) {
            ExitWithMessage(@"Can't save implementation file");
        }
        PrintFormatString(@"'%@.m' has been successfully generated!", sourceName);
    }
    else {
        NSString * fullSource = [NSString stringWithFormat:@"%@%@%@", swiftPart1, swiftPart3, swiftPart2];
        NSData * fileData = [fullSource dataUsingEncoding:NSUTF8StringEncoding];
        NSURL * fileURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.swift",sourceName]];
        
        if ([fileData writeToURL:fileURL atomically:YES] == NO) {
            ExitWithMessage(@"Can't save output file");
        }
        PrintFormatString(@"'%@.swift' has been successfully generated!", sourceName);
    }
    usleep(2000000);
}
@end
