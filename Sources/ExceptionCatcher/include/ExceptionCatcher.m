//
//  Catcher.m
//  ExceptionCatcher
//
//  Created by Dennis Birch on 6/15/20.
//  Copyright © 2020 Dennis Birch. All rights reserved.
//

#import "ExceptionCatcher.h"

@implementation ExceptionCatcher

// https://stackoverflow.com/questions/32758811/catching-nsexception-in-swift

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain: exception.name code: 0 userInfo: exception.userInfo];
        return NO;
    }
}

@end
