//
//  ExceptionCatcher.h
//  ExceptionCatcher
//
//  Created by Dennis Birch on 6/15/20.
//  Copyright © 2020 Dennis Birch. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for ExceptionCatcher.
FOUNDATION_EXPORT double ExceptionCatcherVersionNumber;

//! Project version string for ExceptionCatcher.
FOUNDATION_EXPORT const unsigned char ExceptionCatcherVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ExceptionCatcher/PublicHeader.h>

@interface ExceptionCatcher : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
