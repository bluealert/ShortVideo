//
//  SVCompositionManager.m
//  ShortVideo
//
//  Created by 周涛 on 09/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVCompositionManager.h"
#import "SVCompositionExporter.h"
#import <AVFoundation/AVFoundation.h>

@interface SVCompositionManager ()

@property (nonatomic, copy) NSURL *videoURL;
@property (nonatomic, strong) AVAsset *video;
@property (nonatomic, strong) AVAsset *audio;
@property (nonatomic, assign) NSInteger count;

@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableCompositionTrack *videoTrack;
@property (nonatomic, strong) AVMutableCompositionTrack *audioTrack;

@property (nonatomic, strong) SVCompositionExporter *exporter;

@end

@implementation SVCompositionManager

- (instancetype)initWithVideoURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _count = 0;
        _videoURL = url;
        _composition = [AVMutableComposition composition];
        _exporter = [[SVCompositionExporter alloc] initWithComposition:_composition];
        _videoTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                preferredTrackID:kCMPersistentTrackID_Invalid];
        _audioTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                preferredTrackID:kCMPersistentTrackID_Invalid];
    }
    return self;
}

- (void)loadAssetsAndCompose {
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    
    _video = [AVURLAsset URLAssetWithURL:_videoURL options:options];
    [self loadAsset:_video block:^{
        ++_count;
        if (_count >= 2) {
            [self doCompose];
        }
    }];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"bg" withExtension:@"wav"];
    _audio = [AVURLAsset URLAssetWithURL:url options:options];
    [self loadAsset:_audio block:^{
        ++_count;
        if (_count >= 2) {
            [self doCompose];
        }
    }];
}

- (void)doCompose {
    CMTime cursorTime = kCMTimeZero;
    CMTime duration = _video.duration;
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, duration);

    // 原始视频
    AVAssetTrack *assetTrack = [[_video tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [_videoTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:cursorTime error:nil];

    // 原始视频中的10秒片段
    cursorTime = CMTimeAdd(cursorTime, CMTimeMake(10, 1));
    duration = CMTimeMake(10, 1);
    timeRange = CMTimeRangeMake(CMTimeMake(20, 1), duration);
    for (int i = 0; i < 3; i++) {
        [_videoTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:cursorTime error:nil];
    }

    // 背景音乐
    cursorTime = CMTimeMake(10, 1);
    duration = _audio.duration;
    timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    assetTrack = [[_audio tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [_audioTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:cursorTime error:nil];

    [_exporter beginExport];
}

- (void)loadAsset:(AVAsset*)asset block:(void(^)(void))block {
    NSArray *keys = @[@"tracks", @"duration", @"commonMetadata"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        AVKeyValueStatus tracksStatus = [asset statusOfValueForKey:@"tracks" error:nil];
        AVKeyValueStatus durationStatus = [asset statusOfValueForKey:@"duration" error:nil];
        if (tracksStatus == AVKeyValueStatusLoaded &&
            durationStatus == AVKeyValueStatusLoaded) {
            if (block) {
                block();
            }
        }
    }];
}

@end
