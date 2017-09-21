//
//  SVPreviewView.m
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVPreviewView.h"

@interface SVPreviewView ()

@property (nonatomic) CGRect drawableBounds;

@end

@implementation SVPreviewView

- (instancetype)initWithFrame:(CGRect)frame
                      context:(EAGLContext *)context {
    self = [super initWithFrame:frame
                        context:context];
    if (self) {
        self.frame = frame;
        self.opaque = YES;
        self.enableSetNeedsDisplay = NO;
        self.backgroundColor = [UIColor blackColor];
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        
        _filter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
        
        [self bindDrawable];
        _drawableBounds = self.bounds;
        _drawableBounds.size.width = self.drawableWidth;
        _drawableBounds.size.height = self.drawableHeight;
    }
    return self;
}

- (void)setImage:(CIImage *)sourceImage {
    [self bindDrawable];
    
    [self.filter setValue:sourceImage
                   forKey:kCIInputImageKey];
    
    CIImage *filteredImage = self.filter.outputImage;
    if (filteredImage) {
        CGRect cropRect = SHCenterCropImageRect(sourceImage.extent, self.drawableBounds);
        [self.ciContext drawImage:filteredImage
                                  inRect:_drawableBounds
                                fromRect:cropRect];
    }
    
    [self display];
    [self.filter setValue:nil
                   forKey:kCIInputImageKey];
}

CGRect SHCenterCropImageRect(CGRect sourceRect, CGRect previewRect) {
    CGFloat sourceAspectRatio = sourceRect.size.width / sourceRect.size.height;
    CGFloat previewAspectRatio = previewRect.size.width  / previewRect.size.height;

    CGRect drawRect = sourceRect;
    
    if (sourceAspectRatio > previewAspectRatio) {
        CGFloat scaledHeight = drawRect.size.height * previewAspectRatio;
        drawRect.origin.x += (drawRect.size.width - scaledHeight) / 2.0;
        drawRect.size.width = scaledHeight;
    } else {
        drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspectRatio) / 2.0;
        drawRect.size.height = drawRect.size.width / previewAspectRatio;
    }
    
    return drawRect;
}

@end
