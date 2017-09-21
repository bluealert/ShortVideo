//
//  SVCompositionExporter.h
//  ShortVideo
//
//  Created by 周涛 on 09/11/2016.
//  Copyright © 2016 周涛. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface SVCompositionExporter : NSObject

@property (nonatomic) BOOL exporting;
@property (nonatomic) CGFloat progress;

- (instancetype)initWithComposition:(AVComposition*)composition;

- (void)beginExport;

@end
