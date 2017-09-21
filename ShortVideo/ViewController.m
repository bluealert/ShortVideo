//
//  ViewController.m
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "ViewController.h"
#import "SVPreviewView.h"
#import "SVOverlayView.h"
#import "SVContextManager.h"
#import "SVCameraController.h"

@interface ViewController () <SVOverlayViewDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) SVCameraController *controller;
@property (nonatomic, strong) SVPreviewView *previewView;
@property (nonatomic, strong) SVOverlayView *overlayView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    EAGLContext *eaglContext = [SVContextManager sharedInstance].eaglContext;
    _previewView = [[SVPreviewView alloc] initWithFrame:self.view.bounds
                                                context:eaglContext];
    _previewView.ciContext = [SVContextManager sharedInstance].ciContext;
    [self.view addSubview:_previewView];
    
    _overlayView = [[SVOverlayView alloc] initWithDelegate:self];
    [self.view addSubview:_overlayView];
    
    NSError *error;
    _controller = [[SVCameraController alloc] initWithPreviewView:_previewView];
    if ([_controller setupSession:&error]) {
        [_controller startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
}

- (void)onTouchCaptureButton:(UIButton*)button {
    if (!self.controller.isRecording) {
        [self.controller startRecording];
        [self startTimer];
    } else {
        [self.controller stopRecording];
        [self stopTimer];
    }
    button.selected = !button.selected;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startTimer {
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(updateTimeDisplay)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)updateTimeDisplay {
    CMTime duration = self.controller.recordedDuration;
    NSUInteger time = (NSUInteger)CMTimeGetSeconds(duration);
    NSInteger hours = (time / 3600);
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    
    NSString *format = @"%02i:%02i:%02i";
    NSString *timeString = [NSString stringWithFormat:format, hours, minutes, seconds];
    [_overlayView setElapsedTime:timeString];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
    [_overlayView setElapsedTime:@"00:00:00"];
}

@end
