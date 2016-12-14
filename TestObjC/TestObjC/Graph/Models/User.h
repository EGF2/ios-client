//
//  User.h
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseObject.h"

@interface Address : NSObject
@property NSString *city;
@end

@interface UserName : NSObject
@property NSString *family;
@property NSString *given;
@property NSString *use;
@end

@interface User : BaseObject
@property NSDate *dateOfBirth;
@property NSString *image;
@property NSString *gender;
@property NSString *email;
@property UserName *name;
@property NSArray <Address *> *addresses;
@end

@interface Dimension: NSObject
@property NSInteger width;
@property NSInteger height;
@end

@interface Resize: NSObject
@property NSString *url;
@property Dimension *dimensions;
@end

@interface File: BaseObject
@property NSString *uploadUrl;
@property NSString *mimeType;
@property NSString *title;
@property NSString *user;
@property NSString *url;
@property NSInteger size;
@property BOOL hosted;
@property BOOL uploaded;
@property NSArray <Resize *> *resizes;
@end

@interface Post: BaseObject
@property NSString *designer;
@property NSString *image;
@property File *imageObject;
@end

@interface DesignerRole: BaseObject
@property NSString *user;
@property User *userObject;
@end

@interface Collection: BaseObject
@property NSString *designer;
@property DesignerRole *designerObject;
@property NSString *coverImage;
@property File *coverImageObject;
@end

@interface Product: BaseObject
@property NSString *designer;
@property DesignerRole *designerObject;
@property NSString *coverImage;
@property File *coverImageObject;
@property NSString *collection;
@property Collection *collectionObject;
@end

@interface Message: BaseObject
@property NSString *from;
@property User *fromObject;
@property NSString *to;
@property User *toObject;
@property NSString *subject;
@property NSString *text;
@end

