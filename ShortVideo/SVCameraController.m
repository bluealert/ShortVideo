//
//  SVCameraController.m
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVCameraController.h"
#import "SVMovieWriter.h"
#import "SVCompositionManager.h"
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface SVCameraController () <AVCaptureVideoDataOutputSampleBufferDelegate,
                                  AVCaptureAudioDataOutputSampleBufferDelegate,
                                  SVMovieWriterDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, weak) AVCaptureDeviceInput *activeVideoInput;

@property (nonatomic, strong) SVPreviewView *previewView;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) SVMovieWriter *movieWriter;

@property (nonatomic, strong) SVCompositionManager *manager;

@end

@implementation SVCameraController

- (instancetype)initWithPreviewView:(SVPreviewView*)previewView {
    self = [super init];
    if (self) {
        _previewView = previewView;
        
        _captureSession = [AVCaptureSession new];
        _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        
        _dispatchQueue = dispatch_queue_create("com.shortvideo.CaptureDispatchQueue", NULL);
    }
    return self;
}

- (BOOL)setupSession:(NSError **)error {
    if (![self setupSessionInputs:error]) {
        return NO;
    }
    if (![self setupSessionOutputs:error]) {
        return NO;
    }
    return YES;
}

- (void)startSession {
    dispatch_async(_dispatchQueue, ^{
        if (![_captureSession isRunning]) {
            [_captureSession startRunning];
        }
    });
}

- (void)stopSession {
    dispatch_async(_dispatchQueue, ^{
        if ([_captureSession isRunning]) {
            [_captureSession stopRunning];
        }
    });
}

- (BOOL)setupSessionInputs:(NSError **)error {
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                                                             error:error];
    if (!videoInput) {
        NSLog(@"Failed to create video input.");
        return NO;
    }
    if ([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput];
        _activeVideoInput = videoInput;
    } else {
        NSLog(@"Failed to add video input.");
        return NO;
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                             error:error];
    if (!audioInput) {
        NSLog(@"Failed to create audio input.");
        return NO;
    }
    if ([_captureSession canAddInput:audioInput]) {
        [_captureSession addInput:audioInput];
    } else {
        NSLog(@"Failed to add audio input.");
        return NO;
    }
    
    return YES;
}

- (BOOL)setupSessionOutputs:(NSError **)error {
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.videoSettings = outputSettings;
    _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [_videoDataOutput setSampleBufferDelegate:self
                                        queue:_dispatchQueue];
    
    if ([_captureSession canAddOutput:_videoDataOutput]) {
        [_captureSession addOutput:_videoDataOutput];
    } else {
        NSLog(@"Failed to add video output.");
        return NO;
    }
    
    _audioDataOutput = [AVCaptureAudioDataOutput new];
    [_audioDataOutput setSampleBufferDelegate:self
                                        queue:_dispatchQueue];
    
    if ([_captureSession canAddOutput:_audioDataOutput]) {
        [_captureSession addOutput:_audioDataOutput];
    } else {
        NSLog(@"Failed to add audio output.");
        return NO;
    }
    
    NSDictionary *videoSettings = [_videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    NSDictionary *audioSettings = [_audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    _movieWriter = [[SVMovieWriter alloc] initWithVideoSettings:videoSettings
                                                  audioSettings:audioSettings
                                                  dispatchQueue:_dispatchQueue
                                                       delegate:self];
    
    return YES;
}

- (void)startRecording {
    [_movieWriter startWriting];
    _recording = YES;
}

- (void)stopRecording {
    [_movieWriter stopWriting];
    _recording = NO;
}

- (CMTime)recordedDuration {
    return [_movieWriter recordedDuration];
}

#pragma mark - Delegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    [_movieWriter processSampleBuffer:sampleBuffer];
    
    if (captureOutput == _videoDataOutput) {
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer options:nil];
        [_previewView setImage:sourceImage];
    }
}

- (void)didWriteFinished:(NSURL *)fileURL {
    _manager = [[SVCompositionManager alloc] initWithVideoURL:fileURL];
    [_manager loadAssetsAndCompose];
    /*
    ALAssetsLibrary *library = [ALAssetsLibrary new];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:fileURL]) {
        ALAssetsLibraryWriteVideoCompletionBlock completionBlock;
        completionBlock = ^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"write to assets library failed:%@", [error localizedDescription]);
            }
        };
        [library writeVideoAtPathToSavedPhotosAlbum:fileURL
                                    completionBlock:completionBlock];
    }
    */
}

@end
