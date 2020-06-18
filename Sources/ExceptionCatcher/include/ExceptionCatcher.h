//
//  ExceptionCatcher.h
//  ExceptionCatcher
//
//  Created by Dennis Birch on 6/15/20.
//  Copyright © 2020 Dennis Birch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExceptionCatcher : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
