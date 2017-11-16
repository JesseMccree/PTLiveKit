//
//  VideoCapture.h
//  LiveKit
//
//  Created by ptssg on 2017/11/16.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class VideoCapture;

@protocol VideoCaptureDelegate <NSObject>

- (void)videoCapture:(VideoCapture *)videoCapture
        sampleBuffer:(CVImageBufferRef)sampleBuffer;

@end

@interface VideoCapture : NSObject

@property (nonatomic, weak) id<VideoCaptureDelegate> delegate;

@property (nonatomic, strong) UIView *preView;

- (void)start;

- (void)stop;

@end
