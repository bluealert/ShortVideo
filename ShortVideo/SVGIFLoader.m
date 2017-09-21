//
//  GIFLoader.m
//  ShortVideo
//
//  Created by 周涛 on 09/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVGIFLoader.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

@implementation SVGIFLoader

+ (NSArray*)loadGIFByURL:(NSURL*)URL {
    NSData *data = [NSData dataWithContentsOfURL:URL];
    if (data == nil || data.length <= 0) {
        return nil;
    }
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data,
                                                               (__bridge CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache: @NO});
    if (!imageSource) {
        return nil;
    }
    size_t imageCount = CGImageSourceGetCount(imageSource);
    if (imageCount <= 0) {
        return nil;
    }
    
    NSMutableArray *a = [NSMutableArray new];
    for (size_t i = 0; i < imageCount; i++) {
        @autoreleasepool {
            CGImageRef frameImageRef = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
            if (frameImageRef) {
                UIImage *frameImage = [UIImage imageWithCGImage:frameImageRef];
                if (frameImage) {
                    [a addObject:frameImage];
                }
                CFRelease(frameImageRef);
            }
        }
    }
    
    return a;
}

@end
