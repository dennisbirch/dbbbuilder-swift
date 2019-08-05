//
//  ExceptionCatcher.h
//  DBBBuilder
//
//  Created by Dennis Birch on 1/10/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//


// FROM: https://stackoverflow.com/questions/34956002/how-to-properly-handle-nsfilehandle-exceptions-in-swift-2-0/35003095#35003095

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
