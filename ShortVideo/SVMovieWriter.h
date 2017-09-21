//
//  SVMovieWriter.h
//  ShortVideo
//
//  Created by 周涛 on 08/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol SVMovieWriterDelegate <NSObject>
- (void)didWriteFinished:(NSURL*)fileURL;
@end


@interface SVMovieWriter : NSObject

@property (nonatomic) BOOL isWriting;

- (id)initWithVideoSettings:(NSDictionary *)videoSettings
              audioSettings:(NSDictionary *)audioSettings
              dispatchQueue:(dispatch_queue_t)dispatchQueue
                   delegate:(id<SVMovieWriterDelegate>)delegate;

- (void)startWriting;
- (void)stopWriting;
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (CMTime)recordedDuration;

@end
