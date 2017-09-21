//
//  SVOverlayView.m
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVOverlayView.h"

@interface SVOverlayView ()

@property (nonatomic, strong) UILabel *elapsedTimeLabel;
@property (nonatomic, strong) SVCaptureButton *catptureButton;
@property (nonatomic, weak) id<SVOverlayViewDelegate> delegate;

@end

@implementation SVOverlayView

- (instancetype)initWithDelegate:(id<SVOverlayViewDelegate>)delegate {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.frame = [UIScreen mainScreen].bounds;
        
        UIView *view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 146)];
        view1.backgroundColor = [UIColor blackColor];
        [self addSubview:view1];
        
        UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 521, 375, 146)];
        view2.backgroundColor = [UIColor blackColor];
        [self addSubview:view2];
        
        _delegate = delegate;
        
        _elapsedTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(130, 30, 115, 115)];
        _elapsedTimeLabel.text = @"00:00:00";
        _elapsedTimeLabel.textColor = [UIColor redColor];
        _elapsedTimeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_elapsedTimeLabel];
        
        _catptureButton = [[SVCaptureButton alloc] initWithFrame:CGRectMake(150, 556, 75, 75)];
        [self addSubview:_catptureButton];
        
        [_catptureButton addTarget:self action:@selector(onTouch) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)onTouch {
    [_delegate onTouchCaptureButton:_catptureButton];
}

- (void)setElapsedTime:(NSString*)time {
    _elapsedTimeLabel.text = time;
}

@end
