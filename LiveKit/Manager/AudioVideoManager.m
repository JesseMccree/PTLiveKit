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

@property (nonatomic, strong) QueueManager *queue;

@end

@implementation AudioVideoManager

- (id)initWithVideoConfig:(VideoConfig *)videoConfig
              AudioConfig:(AudioConfig *)audioConfig {
    self = [super init];
    if (self) {
        _videoConfig = videoConfig;
        _audioConfig = audioConfig;
        _isSendAVCC = NO;
        _isSendSpec = NO;
        rtmpQueue = dispatch_queue_create("com.live.rtmp", DISPATCH_QUEUE_SERIAL);
        [self initManager];
    }
    return self;
}

- (VideoManager *)videoManager {
    if (!_videoManager) {
        _videoManager = [[VideoManager alloc]initWithVideoConfig:_videoConfig];
        _videoManager.delegate = self;
    }
    return _videoManager;
}

- (AudioManager *)audioManager {
    if (!_audioManager) {
        _audioManager = [[AudioManager alloc]initWithAudioConfig:_audioConfig];
        _audioManager.delegate = self;
    }
    return _audioManager;
}

- (RtmpManager *)rtmpManager {
    if (!_rtmpManager) {
        _rtmpManager = [[RtmpManager alloc]init];
        [_rtmpManager rtmpConnect:@"rtmp://10.201.8.137:1935/rtmplive/demo"];
    }
    return _rtmpManager;
}

- (QueueManager *)queue {
    if (!_queue) {
        _queue = [[QueueManager alloc]init];
    }
    return _queue;
}

- (void)initManager {
    _videoCapture = [[VideoCapture alloc]init];
    _videoCapture.delegate = self;
    _preView = _videoCapture.preView;

    _audioCapture = [[AudioCapture alloc]init];
    _audioCapture.delegate = self;
}

#pragma mark - VideoCaptureDelegate AudioCaptureDelegate
- (void)videoCapture:(VideoCapture *)videoCapture sampleBuffer:(CVImageBufferRef)sampleBuffer {
    [self.videoManager encoderToH264:sampleBuffer];
}

- (void)audioCapture:(AudioCapture *)videoCapture buffers:(AudioBufferList)buffers {
    [self.audioManager encoderToAAC:buffers];
}

#pragma mark - VideoManagerDelegate AudioManagerDelegate
- (void)videoManager:(VideoManager *)videoManager videoFrame:(VideoFrame *)videoFrame {
    [self.queue addObject:videoFrame];
    [self sendFrame];
}

- (void)audioManager:(AudioManager *)audioManager audioFrame:(AudioFrame *)audioFrame {
    [self.queue addObject:audioFrame];
    [self sendFrame];
}

- (void)sendFrame {
    AudioVideoFrame *avf = [self.queue popObject];
    if (avf) {
        if ([avf isKindOfClass:[VideoFrame class]]) {
            [self sendVideo:(VideoFrame *)avf];
        }else if ([avf isKindOfClass:[AudioFrame class]]) {
            [self sendAudio:(AudioFrame *)avf];
        }
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
    
    [self.videoCapture start];
    [self.audioCapture start];
}

- (void)stop {
    
    [self.videoCapture stop];
    [self.audioCapture stop];
}

@end
