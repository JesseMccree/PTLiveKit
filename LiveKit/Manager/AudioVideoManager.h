//
//  AudioVideoManager.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpManager.h"
#import "QueueManager.h"
#import "VideoManager.h"
#import "AudioManager.h"
#import "VideoCapture.h"
#import "AudioCapture.h"

@interface AudioVideoManager : NSObject

@property (nonatomic, strong) UIView *preView;

- (id)initWithVideoConfig:(VideoConfig *)videoConfig
              AudioConfig:(AudioConfig *)audioConfig;

- (void)start;

- (void)stop;

@end
