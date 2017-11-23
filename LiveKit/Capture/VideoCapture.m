//
//  VideoCapture.m
//  LiveKit
//
//  Created by ptssg on 2017/11/16.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "VideoCapture.h"
#import "GPUImage.h"

@interface VideoCapture ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;

@property (nonatomic, strong) GPUImageView *gpuImageView;

@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *output;

@end

@implementation VideoCapture

- (id)init {
    self = [super init];
    if (self) {
        [self initSession];
    }
    return self;
}

- (void)initSession {
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    _videoCamera.outputImageOrientation = AVCaptureVideoOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.frameRate = (int32_t)24;
    
    _gpuImageView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [_gpuImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    _preView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [_preView addSubview:_gpuImageView];
}

- (void)processVideo:(GPUImageOutput *)output {
    __weak __typeof(self)weakself = self;
    @autoreleasepool {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        
        if ([weakself.delegate conformsToProtocol:@protocol(VideoCaptureDelegate)] &&
            [weakself.delegate respondsToSelector:@selector(videoCapture:sampleBuffer:)]) {
            [weakself.delegate videoCapture:weakself sampleBuffer:pixelBuffer];
        }
    }
}

- (void)start {
    [self.videoCamera removeAllTargets];
    [self.output removeAllTargets];

    self.output = [[GPUImageFilter alloc] init];

    [self.videoCamera addTarget:self.output];
    [self.output addTarget:self.gpuImageView];
    
    __weak __typeof(self)weakself = self;
    [self.output setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        [weakself processVideo:output];
    }];
    [_videoCamera startCameraCapture];
}

- (void)stop {
    [_videoCamera stopCameraCapture];
}

@end
