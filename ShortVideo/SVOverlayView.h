//
//  SVOverlayView.h
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVCaptureButton.h"

@protocol SVOverlayViewDelegate <NSObject>

- (void)onTouchCaptureButton:(UIButton*)button;

@end


@interface SVOverlayView : UIView

- (instancetype)initWithDelegate:(id<SVOverlayViewDelegate>)delegate;
- (void)setElapsedTime:(NSString*)time;

@end
