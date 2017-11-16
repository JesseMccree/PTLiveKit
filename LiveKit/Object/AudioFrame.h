//
//  AudioFrame.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "AudioVideoFrame.h"

@interface AudioFrame : AudioVideoFrame

@property (nonatomic, strong) NSData *sequenceHeader;

@end

@interface AudioConfig : NSObject

/**
 采样率
 */
@property (nonatomic, assign) Float64 mSampleRate;

/**
 声道数
 */
@property (nonatomic, assign) UInt32 mChannelsPerFrame;

@end
