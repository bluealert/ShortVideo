//
//  SVContextManager.m
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVContextManager.h"

@implementation SVContextManager

+ (instancetype)sharedInstance {
    static dispatch_once_t predicate;
    static SVContextManager *instance = nil;
    dispatch_once(&predicate, ^{instance = [self new];});
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSDictionary *options = @{kCIContextWorkingColorSpace : [NSNull null]};
        _ciContext = [CIContext contextWithEAGLContext:_eaglContext
                                               options:options];
    }
    return self;
}

@end
