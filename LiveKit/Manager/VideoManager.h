//
//  VideoManager.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoFrame.h"

@class VideoManager;

@protocol VideoManagerDelegate <NSObject>

- (void)videoManager:(VideoManager *)videoManager
          videoFrame:(VideoFrame *)videoFrame;

@end

@interface VideoManager : NSObject

@property (nonatomic, weak) id<VideoManagerDelegate> delegate;

- (id)initWithVideoConfig:(VideoConfig *)videoConfig;

//- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer;
- (void)encoderToH264:(CVImageBufferRef)sampleBuffer;
@end
