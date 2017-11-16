//
//  QueueManager.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioFrame.h"
#import "VideoFrame.h"

@interface QueueManager : NSObject

- (void)addObject:(AudioVideoFrame *)obj;

- (AudioVideoFrame *)popObject;

@end
