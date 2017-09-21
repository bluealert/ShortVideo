//
//  SVCompositionExporter.m
//  ShortVideo
//
//  Created by 周涛 on 09/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import "SVCompositionExporter.h"
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface SVCompositionExporter ()

@property (strong, nonatomic) AVComposition* composition;
@property (strong, nonatomic) AVAssetExportSession *exportSession;

@end

@implementation SVCompositionExporter

- (instancetype)initWithComposition:(AVComposition*)composition {
    self = [super init];
    if (self) {
        _composition = composition;
    }
    return self;
}

- (void)beginExport {
    self.exportSession = [AVAssetExportSession exportSessionWithAsset:_composition
                                                           presetName:AVAssetExportPresetMediumQuality];
    self.exportSession.outputURL = [self exportURL];
    self.exportSession.outputFileType = AVFileTypeMPEG4;
    
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AVAssetExportSessionStatus status = self.exportSession.status;
            if (status == AVAssetExportSessionStatusCompleted) {
                [self writeExportedVideoToAssetsLibrary];
            } else {
                NSLog(@"Export composition Failed");
            }
        });
    }];
    
    self.exporting = YES;
    [self monitorExportProgress];
}

- (void)monitorExportProgress {
    double delayInSeconds = 0.1;
    int64_t delta = (int64_t)delayInSeconds * NSEC_PER_SEC;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delta);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        
        AVAssetExportSessionStatus status = self.exportSession.status;
        
        if (status == AVAssetExportSessionStatusExporting) {
            
            self.progress = self.exportSession.progress;
            [self monitorExportProgress];
            
        } else {
            self.exporting = NO;
        }
    });
}

- (void)writeExportedVideoToAssetsLibrary {
    NSURL *exportURL = self.exportSession.outputURL;
    ALAssetsLibrary *library = [ALAssetsLibrary new];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:exportURL
                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                        if (error) {
                                            NSLog(@"Unable to write to Photos library.");
                                        } else {
                                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频合成" message:@"视频合成成功，请到相册中播放" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                            [alert show];
                                        }
                                        
                                        [[NSFileManager defaultManager] removeItemAtURL:exportURL
                                                                                  error:nil];
                                    }];
    } else {
        NSLog(@"Video could not be exported to assets library.");
    }
    self.exportSession = nil;
}

- (NSURL *)exportURL {
    NSString *filePath = nil;
    NSUInteger count = 0;
    do {
        filePath = NSTemporaryDirectory();
        NSString *numberString = count > 0 ?
        [NSString stringWithFormat:@"-%li", (unsigned long) count] : @"";
        NSString *fileNameString =
        [NSString stringWithFormat:@"composition-%@.mp4", numberString];
        filePath = [filePath stringByAppendingPathComponent:fileNameString];
        count++;
    } while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    
    return [NSURL fileURLWithPath:filePath];
}

@end
