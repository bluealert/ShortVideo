//
//  SVMovieWriter.m
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVMovieWriter.h"
#import "SVGIFLoader.h"
#import "SVContextManager.h"
#import <CoreImage/CoreImage.h>

static NSString *const SHVideoFilename = @"movie.mp4";

@interface SVMovieWriter ()

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@property (nonatomic, weak) CIContext *ciContext;
@property (nonatomic, assign) CGColorSpaceRef colorSpace;
@property (nonatomic, strong) CIFilter *ciFilter;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *audioSettings;

@property (nonatomic) BOOL firstSample;
@property (nonatomic) CMTime startTime;
@property (nonatomic) CMTime duration;

@property (nonatomic, strong) NSArray *gifImages;
@property (nonatomic, assign) NSInteger gifIndex;

@property (nonatomic, weak) id<SVMovieWriterDelegate> delegate;

@end

@implementation SVMovieWriter

- (id)initWithVideoSettings:(NSDictionary *)videoSettings
              audioSettings:(NSDictionary *)audioSettings
              dispatchQueue:(dispatch_queue_t)dispatchQueue
                   delegate:(id<SVMovieWriterDelegate>)delegate {
    self = [super init];
    if (self) {
        _videoSettings = videoSettings;
        _audioSettings = audioSettings;
        _dispatchQueue = dispatchQueue;
        _delegate = delegate;
        
        _ciContext = [SVContextManager sharedInstance].ciContext;
        _colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _ciFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
        _firstSample = YES;
        _duration = kCMTimeZero;
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"bird" withExtension:@"gif"];
        _gifImages = [SVGIFLoader loadGIFByURL:url];
        _gifIndex = 0;
    }
    return self;
}

- (void)dealloc {
    CGColorSpaceRelease(_colorSpace);
}

- (void)startWriting {
    dispatch_async(_dispatchQueue, ^{
        NSError *error = nil;
        _assetWriter = [AVAssetWriter assetWriterWithURL:[self outputURL]
                                                fileType:AVFileTypeMPEG4
                                                   error:&error];
        if (!_assetWriter || error) {
            NSString *formatString = @"Could not create AVAssetWriter: %@";
            NSLog(@"%@", [NSString stringWithFormat:formatString, error]);
            return ;
        }
        
        _assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                outputSettings:_videoSettings];
        _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
        
        NSDictionary *attributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (id)kCVPixelBufferWidthKey : _videoSettings[AVVideoWidthKey],
                                     (id)kCVPixelBufferHeightKey : _videoSettings[AVVideoHeightKey],
                                     (id)kCVPixelFormatOpenGLESCompatibility : (id)kCFBooleanTrue};
        _pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:attributes];
        
        if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
            [_assetWriter addInput:_assetWriterVideoInput];
        } else {
            NSLog(@"Unable to add video input.");
            return;
        }
        
        _assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                outputSettings:_audioSettings];
        _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
            [_assetWriter addInput:_assetWriterAudioInput];
        } else {
            NSLog(@"Unable to add audio input.");
            return;
        }
        
        _isWriting = YES;
        _firstSample = YES;
    });
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_isWriting) {
        return;
    }
    
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (mediaType == kCMMediaType_Video) {
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if (_firstSample) {
            _startTime = timestamp;
            if ([_assetWriter startWriting]) {
                [_assetWriter startSessionAtSourceTime:timestamp];
            } else {
                NSLog(@"Failed to start writing.");
            }
            _firstSample = NO;
        }
        
        CVPixelBufferRef outputRenderBuffer = NULL;
        CVPixelBufferPoolRef pixelBufferPool = _pixelBufferAdaptor.pixelBufferPool;
        OSStatus err = CVPixelBufferPoolCreatePixelBuffer(NULL, pixelBufferPool, &outputRenderBuffer);
        if (err) {
            NSLog(@"Unable to obtain a pixel buffer from the pool.");
            return;
        }
        
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer options:nil];
        [_ciFilter setValue:sourceImage forKey:kCIInputImageKey];
        
        CIImage *filteredImage = _ciFilter.outputImage;
        if (!filteredImage) {
            filteredImage = sourceImage;
        }
        
        // 插入GIF动画
        if (CMTimeGetSeconds(_duration) >= 3 && _gifIndex < _gifImages.count) {
            UIImage *frameImage = [UIImage imageWithCIImage:filteredImage];
            UIImage *gifImage = _gifImages[_gifIndex++];
            
            CGSize size = CGSizeMake(frameImage.size.width, frameImage.size.height);
            UIGraphicsBeginImageContext(size);
            
            [frameImage drawInRect:CGRectMake(0, 0, size.width, frameImage.size.height)];
            [gifImage drawInRect:CGRectMake(0, 0, size.width, gifImage.size.height)];
            
            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            filteredImage = [[CIImage alloc] initWithCGImage:finalImage.CGImage options:nil];
        }
        
        [_ciContext render:filteredImage
           toCVPixelBuffer:outputRenderBuffer
                    bounds:filteredImage.extent
                colorSpace:_colorSpace];
        
        if (_assetWriterVideoInput.isReadyForMoreMediaData) {
            if (![_pixelBufferAdaptor appendPixelBuffer:outputRenderBuffer
                                   withPresentationTime:timestamp]) {
                NSLog(@"Error appending pixel buffer.");
            } else {
                _duration = CMTimeSubtract(timestamp, _startTime);
            }
        } else {
            NSLog(@"Not ready for more video data");
        }
    } else if (!_firstSample && mediaType == kCMMediaType_Audio) {
        if (_assetWriterAudioInput.isReadyForMoreMediaData) {
            if (![_assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending audio sample buffer.");
            }
        } else {
            NSLog(@"Not ready for more audio data");
        }
    }
}

- (void)stopWriting {
    _isWriting = NO;
    dispatch_async(_dispatchQueue, ^{
        [_assetWriter finishWritingWithCompletionHandler:^{
            if (_assetWriter.status == AVAssetWriterStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate didWriteFinished:[_assetWriter outputURL]];
                });
            } else {
                NSLog(@"Failed to write movie: %@", _assetWriter.error);
            }
        }];
    });
}

- (NSURL *)outputURL {
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:SHVideoFilename];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
    return url;
}

- (CMTime)recordedDuration {
    return _duration;
}

@end
