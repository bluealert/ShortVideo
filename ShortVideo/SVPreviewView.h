//
//  SVPreviewView.h
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface SVPreviewView : GLKView

- (void)setImage:(CIImage *)image;

@property (nonatomic, strong) CIFilter *filter;
@property (nonatomic, strong) CIContext *ciContext;

@end
