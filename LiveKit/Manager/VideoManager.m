//
//  VideoManager.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "VideoManager.h"
#import <VideoToolbox/VideoToolbox.h>

@interface VideoManager () {
    VTCompressionSessionRef compressionSession;
    int frameCount;
}

@property (nonatomic, strong) NSData *sps;

@property (nonatomic, strong) NSData *pps;

@property (nonatomic, strong) VideoConfig *videoConfig;

@end

@implementation VideoManager

- (id)initWithVideoConfig:(VideoConfig *)videoConfig {
    self = [super init];
    if (self) {
        _videoConfig = videoConfig;
        [self initSession];
    }
    return self;
}

- (void)initSession {
    if (compressionSession) {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    
    frameCount = 0;
    OSStatus status = VTCompressionSessionCreate(NULL, _videoConfig.width, _videoConfig.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoToolCompressionOutputCallback, (__bridge void * _Nullable)(self), &compressionSession);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed:%d",(int)status);
    }
    
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@(_videoConfig.fps)));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@(_videoConfig.fps*2)));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(2));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_videoConfig.bitrate));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(_videoConfig.bitrate*2/8), @1]);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
}

- (void)encoderToH264:(CVImageBufferRef)sampleBuffer {
    CMTime pts = CMTimeMake(frameCount++, _videoConfig.fps);
    CMTime duration = CMTimeMake(1, _videoConfig.fps);
    VTEncodeInfoFlags flags;
    NSDictionary *properties = nil;
    if (frameCount % _videoConfig.fps*2 == 0) {
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
    }
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, sampleBuffer, pts, duration, (__bridge CFDictionaryRef)properties, NULL, &flags);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionEncodeFrame failed:%d",(int)status);
    }
}

static void VideoToolCompressionOutputCallback(void *outputCallbackRefCon,
                                               void *sourceFrameRefCon,
                                               OSStatus status,
                                               VTEncodeInfoFlags infoFlags,
                                               CMSampleBufferRef sampleBuffer) {
    if (status != noErr) {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }

    VideoManager *manager = (__bridge VideoManager *)outputCallbackRefCon;

    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dictionary = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);

    //kCMSampleAttachmentKey_NotSync为true时为非关键帧
    BOOL keyframe = !CFDictionaryContainsKey(dictionary, kCMSampleAttachmentKey_NotSync);
    if (keyframe && !manager.sps) {

        const unsigned char *sps,*pps;
        size_t spslen,ppslen;

        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus status1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription, 0, &sps, &spslen, NULL, 0);
        OSStatus status2 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription, 1, &pps, &ppslen, NULL, 0);

        if (status1 == noErr && status2 == noErr) {
            manager.sps = [NSData dataWithBytes:sps length:spslen];
            manager.pps = [NSData dataWithBytes:pps length:ppslen];
        }
    }

    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lengthAtOffset,totalLength;
    char *dataPointer;
    OSStatus status0 = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &dataPointer);
    if (status0 == noErr) {
        size_t offset = 0;
        while (offset < totalLength - 4) {
            uint32_t naluLength = 0;
            memcpy(&naluLength, dataPointer+offset, 4);
            naluLength = CFSwapInt32BigToHost(naluLength);

            VideoFrame *vf = [VideoFrame new];
            vf.data = [NSData dataWithBytes:dataPointer+offset+4 length:naluLength];
            vf.sps = manager.sps;
            vf.pps = manager.pps;
            vf.isKeyFrame = keyframe;

            if ([manager.delegate conformsToProtocol:@protocol(VideoManagerDelegate)] &&
                [manager.delegate respondsToSelector:@selector(videoManager:videoFrame:)]) {
                [manager.delegate videoManager:manager videoFrame:vf];
            }
            //可能包含多个nalu
            offset += 4 + naluLength;
        }
    }
}

@end
