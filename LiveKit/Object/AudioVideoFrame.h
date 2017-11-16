//
//  AudioVideoFrame.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FrameType) {
    Audio,
    Video,
};

@interface AudioVideoFrame : NSObject

@property (nonatomic, strong) NSData *data;

@property (nonatomic, assign) FrameType type;

@end
