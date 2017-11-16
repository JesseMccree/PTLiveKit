//
//  VideoFrame.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "AudioVideoFrame.h"

@interface VideoFrame : AudioVideoFrame

@property (nonatomic, strong) NSData *sps;

@property (nonatomic, strong) NSData *pps;

@property (nonatomic, assign) BOOL isKeyFrame;

@end

@interface VideoConfig : NSObject

@property (nonatomic, assign) int width;

@property (nonatomic, assign) int height;

@property (nonatomic, assign) int fps;

@property (nonatomic, assign) int bitrate;

@end
