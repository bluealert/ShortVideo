//
//  SVContextManager.h
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface SVContextManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) EAGLContext *eaglContext;
@property (nonatomic, strong, readonly) CIContext *ciContext;

@end
