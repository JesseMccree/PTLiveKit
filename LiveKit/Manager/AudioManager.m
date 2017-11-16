//
//  AudioManager.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "AudioManager.h"

@interface AudioManager ()

@property (nonatomic, assign) AudioConverterRef avr;

@property (nonatomic, strong) AudioConfig *audioConfig;

@end

@implementation AudioManager

- (id)init {
    self = [super init];
    if (self) {
        [self initSession];
    }
    return self;
}

- (id)initWithAudioConfig:(AudioConfig *)audioConfig {
    self = [super init];
    if (self) {
        _audioConfig = audioConfig;
        [self initSession];
    }
    return self;
}

- (void)initSession {
    
    AudioStreamBasicDescription inAsbd = {0};
    inAsbd.mSampleRate = _audioConfig.mSampleRate;
    inAsbd.mFormatID = kAudioFormatLinearPCM;
    inAsbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    inAsbd.mChannelsPerFrame = _audioConfig.mChannelsPerFrame;
    inAsbd.mFramesPerPacket = 1;
    inAsbd.mBitsPerChannel = 16;
    inAsbd.mBytesPerFrame = inAsbd.mBitsPerChannel / 8 * inAsbd.mChannelsPerFrame;
    inAsbd.mBytesPerPacket = inAsbd.mBytesPerFrame * inAsbd.mFramesPerPacket;
    
    AudioStreamBasicDescription outAsbd;
    memset(&outAsbd, 0, sizeof(outAsbd));
    outAsbd.mSampleRate = inAsbd.mSampleRate;
    outAsbd.mFormatID = kAudioFormatMPEG4AAC;
    outAsbd.mChannelsPerFrame = _audioConfig.mChannelsPerFrame;
    outAsbd.mFramesPerPacket = 1024;
    
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    
    OSStatus result = AudioConverterNewSpecific(&inAsbd, &outAsbd, 2, requestedCodecs, &_avr);
    UInt32 outputBitrate = 128000;
    UInt32 propSize = sizeof(outputBitrate);
    if (result == noErr) {
        AudioConverterSetProperty(_avr, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }
}

- (void)encoderToAAC:(AudioBufferList )buffers {
    AudioBufferList outBuffers;
    outBuffers.mNumberBuffers = 1;
    outBuffers.mBuffers[0].mNumberChannels = buffers.mBuffers[0].mNumberChannels;
    outBuffers.mBuffers[0].mDataByteSize = buffers.mBuffers[0].mDataByteSize;
    outBuffers.mBuffers[0].mData = malloc(buffers.mBuffers[0].mDataByteSize);
    
    UInt32 ioOutputDataPacketSize = 1;
    
    OSStatus status = AudioConverterFillComplexBuffer(_avr, inputDataProc, &buffers, &ioOutputDataPacketSize, &outBuffers, NULL);
    if (status != noErr) {
        NSLog(@"AudioConverterFillComplexBuffer failed:%d",(int)status);
    }
    
    if ([_delegate conformsToProtocol:@protocol(AudioManagerDelegate)] &&
        [_delegate respondsToSelector:@selector(audioManager:audioFrame:)]) {
        
        unsigned char aac[2];
        aac[0] = 0x12;
        aac[1] = 0x10;
        
        AudioFrame *af = [AudioFrame new];
        af.data = [NSData dataWithBytes:outBuffers.mBuffers[0].mData length:outBuffers.mBuffers[0].mDataByteSize];
        af.type = Audio;
        af.sequenceHeader = [NSData dataWithBytes:aac length:2];
        [_delegate audioManager:self audioFrame:af];
    }
}

static OSStatus inputDataProc(AudioConverterRef inAudioConverter,
                              UInt32 *ioNumberDataPackets,
                              AudioBufferList *ioData,
                              AudioStreamPacketDescription * __nullable * __nullable outDataPacketDescription,
                              void * __nullable inUserData) {
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}

@end
