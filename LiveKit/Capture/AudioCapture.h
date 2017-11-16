//
//  AudioCapture.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AudioCapture;

@protocol AudioCaptureDelegate <NSObject>

- (void)audioCapture:(AudioCapture *)videoCapture
             buffers:(AudioBufferList)buffers;

@end

@interface AudioCapture : NSObject

@property (nonatomic, weak) id<AudioCaptureDelegate> delegate;

- (void)start;

- (void)stop;

@end
