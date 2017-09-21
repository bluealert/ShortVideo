//
//  GIFLoader.h
//  ShortVideo
//
//  Created by 周涛 on 09/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVGIFLoader : NSObject

+ (NSArray*)loadGIFByURL:(NSURL*)URL;

@end
