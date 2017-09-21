//
//  SVCameraController.h
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVPreviewView.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SVCameraController : NSObject

- (instancetype)initWithPreviewView:(SVPreviewView*)previewView;
- (BOOL)setupSession:(NSError **)error;
- (void)startSession;
- (void)stopSession;
- (void)startRecording;
- (void)stopRecording;
- (CMTime)recordedDuration;

@property (nonatomic, getter = isRecording) BOOL recording;

@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;
@property (nonatomic, strong, readonly) dispatch_queue_t dispatchQueue;

@end
