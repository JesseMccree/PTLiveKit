//
//  AudioCapture.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "AudioCapture.h"

@interface AudioCapture ()

@property (nonatomic, strong) AVAudioSession *session;

@property (nonatomic, assign) AudioComponent component;

@property (nonatomic, assign) AudioComponentInstance componentInstance;

@end

@implementation AudioCapture

- (id)init {
    self = [super init];
    if (self) {
        _session = [AVAudioSession sharedInstance];

        AudioComponentDescription acd;
        //Remote I/O unit
        acd.componentType = kAudioUnitType_Output;
        acd.componentSubType = kAudioUnitSubType_RemoteIO;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        
        _component = AudioComponentFindNext(NULL, &acd);
        AudioComponentInstanceNew(_component, &_componentInstance);
        
        UInt32 flag = 1;
        
        AudioUnitSetProperty(_componentInstance,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Input,
                             1,
                             &flag,
                             sizeof(flag));
        
        
        AudioStreamBasicDescription asbd = {0};
        asbd.mSampleRate = 44100;
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
        asbd.mChannelsPerFrame = 2;
        asbd.mFramesPerPacket = 1;
        asbd.mBitsPerChannel = 16;
        asbd.mBytesPerFrame = asbd.mBitsPerChannel / 8 * asbd.mChannelsPerFrame;
        asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;
        
        AudioUnitSetProperty(_componentInstance,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Output,
                             1,
                             &asbd,
                             sizeof(asbd));
        
        AURenderCallbackStruct cbs;
        cbs.inputProc = inputCallback;
        cbs.inputProcRefCon = (__bridge void * _Nullable)(self);
        
        AudioUnitSetProperty(_componentInstance,
                             kAudioOutputUnitProperty_SetInputCallback,
                             kAudioUnitScope_Global,
                             1,
                             &cbs,
                             sizeof(cbs));
        
        AudioUnitInitialize(_componentInstance);
        
        [_session setPreferredSampleRate:44100 error:nil];
        [_session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
        [_session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
        [_session setActive:YES error:nil];
    }
    return self;
}

static OSStatus inputCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList * __nullable ioData) {
    AudioCapture *manager = (__bridge AudioCapture *)inRefCon;
    
    AudioBuffer buffer;
    buffer.mData = NULL;
    buffer.mDataByteSize = 0;
    buffer.mNumberChannels = 1;
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status = AudioUnitRender(manager.componentInstance,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      &bufferList);
    
    if ([manager.delegate conformsToProtocol:@protocol(AudioCaptureDelegate)] &&
        [manager.delegate respondsToSelector:@selector(audioCapture:buffers:)]) {
        [manager.delegate audioCapture:manager buffers:bufferList];
    }
    
    return status;
}

- (void)start {
    [_session setCategory:AVAudioSessionCategoryPlayAndRecord        withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
    AudioOutputUnitStart(_componentInstance);
}

- (void)stop {
    AudioOutputUnitStop(_componentInstance);
}

@end
