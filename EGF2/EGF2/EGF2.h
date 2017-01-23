//
//  EGF2.h
//  EGF2
//
//  Created by LuzanovRoman on 03.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for EGF2.
FOUNDATION_EXPORT double EGF2VersionNumber;

//! Project version string for EGF2.
FOUNDATION_EXPORT const unsigned char EGF2VersionString[];

// User info keys
extern NSString * const EGF2EdgeInfoKey;
extern NSString * const EGF2ObjectIdInfoKey;
extern NSString * const EGF2EdgeObjectIdInfoKey;
extern NSString * const EGF2EdgeObjectsInfoKey;
extern NSString * const EGF2EdgeObjectsCountInfoKey;

// For Objective-C only
extern NSString * const EGF2NotificationEdgeCreated;
extern NSString * const EGF2NotificationEdgeRemoved;
extern NSString * const EGF2NotificationObjectUpdated;
extern NSString * const EGF2NotificationObjectDeleted;

extern NSString * const EGF2NotificationEdgeLocallyRefreshed;
extern NSString * const EGF2NotificationEdgeLocallyPageLoaded;
