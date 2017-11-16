//
//  AudioVideoManager.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "AudioVideoManager.h"

@interface AudioVideoManager ()<AudioCaptureDelegate,VideoManagerDelegate,AudioManagerDelegate,VideoCaptureDelegate> {
    dispatch_queue_t rtmpQueue;
}

@property (nonatomic, assign) BOOL isSendAVCC;

@property (nonatomic, assign) BOOL isSendSpec;

@property (nonatomic, strong) VideoManager *videoManager;

@property (nonatomic, strong) AudioManager *audioManager;

@property (nonatomic, strong) VideoCapture *videoCapture;

@property (nonatomic, strong) AudioCapture *audioCapture;

@property (nonatomic, strong) VideoConfig *videoConfig;

@property (nonatomic, strong) AudioConfig *audioConfig;

@property (nonatomic, strong) RtmpManager *rtmpManager;

@property (nonatomic, strong) QueueManager *videoQueue;

@property (nonatomic, strong) QueueManager *audioQueue;

@end

@implementation AudioVideoManager

- (id)initWithVideoConfig:(VideoConfig *)videoConfig
              AudioConfig:(AudioConfig *)audioConfig {
    self = [super init];
    if (self) {
        _videoConfig = videoConfig;
        _audioConfig = audioConfig;
        rtmpQueue = dispatch_queue_create("com.live.rtmp", DISPATCH_QUEUE_SERIAL);
        [self initManager];
    }
    return self;
}

- (void)initManager {
    _isSendAVCC = NO;
    _isSendSpec = NO;
    
    _videoCapture = [[VideoCapture alloc]init];
    _videoCapture.delegate = self;
    _preView = _videoCapture.preView;
    
    _audioCapture = [[AudioCapture alloc]init];
    _audioCapture.delegate = self;
    
    _videoManager = [[VideoManager alloc]initWithVideoConfig:_videoConfig];
    _videoManager.delegate = self;
    
    _audioManager = [[AudioManager alloc]initWithAudioConfig:_audioConfig];
    _audioManager.delegate = self;
    
    _rtmpManager = [[RtmpManager alloc]init];
    [_rtmpManager rtmpConnect:@"rtmp://10.201.8.130:1935/rtmplive/demo"];
    
    _audioQueue = [[QueueManager alloc]init];
    _videoQueue = [[QueueManager alloc]init];
}

#pragma mark - VideoCaptureDelegate AudioCaptureDelegate
- (void)videoCapture:(VideoCapture *)videoCapture sampleBuffer:(CVImageBufferRef)sampleBuffer {
    [_videoManager encoderToH264:sampleBuffer];
}

- (void)audioCapture:(AudioCapture *)videoCapture buffers:(AudioBufferList)buffers {
    [_audioManager encoderToAAC:buffers];
}

#pragma mark - VideoManagerDelegate AudioManagerDelegate
- (void)videoManager:(VideoManager *)videoManager videoFrame:(VideoFrame *)videoFrame {
    [_videoQueue addObject:videoFrame];
    [self sendVideo];
}

- (void)audioManager:(AudioManager *)audioManager audioFrame:(AudioFrame *)audioFrame {
    [_audioQueue addObject:audioFrame];
    [self sendAudio];
}

- (void)sendVideo {
    AudioVideoFrame *avf = [_videoQueue popObject];
    if (avf) {
        [self sendVideo:(VideoFrame *)avf];
    }
}

- (void)sendVideo:(VideoFrame *)videoframe {
    __weak __typeof(self)weakself = self;
    
    dispatch_async(rtmpQueue, ^{
        if (!weakself.isSendAVCC) {
            weakself.isSendAVCC = YES;
            [weakself.rtmpManager sendAVCCSps:videoframe.sps Pps:videoframe.pps];
        }else {
            [weakself.rtmpManager sendAVCFrame:videoframe.data isKeyFrame:videoframe.isKeyFrame];
        }
    });
}

- (void)sendAudio {
    AudioVideoFrame *avf = [_audioQueue popObject];
    if (avf) {
        [self sendAudio:(AudioFrame *)avf];
    }
}

- (void)sendAudio:(AudioFrame *)audioframe {
    __weak __typeof(self)weakself = self;
    
    dispatch_async(rtmpQueue, ^{
        if (!weakself.isSendSpec) {
            weakself.isSendSpec = YES;
            [weakself.rtmpManager sendAACSpec:audioframe.sequenceHeader];
        }else {
            [weakself.rtmpManager sendAACFrame:audioframe.data];
        }
    });
}

- (void)start {
    
    [_videoCapture start];
    [_audioCapture start];
}

- (void)stop {
    
    [_videoCapture stop];
    [_audioCapture stop];
}

@end
