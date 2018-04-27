//
//  QueueManager.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "QueueManager.h"
#import "VideoFrame.h"

#define MAXCount 600

@interface QueueManager () {
    dispatch_semaphore_t _lock;
}

@property (nonatomic, strong) NSMutableArray *queue;

@end

@implementation QueueManager

- (id)init {
    self = [super init];
    if (self) {
        _queue = [NSMutableArray array];
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)addObject:(AudioVideoFrame *)obj {
    if (!obj) {
        return;
    }
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (_queue.count < MAXCount) {
        [_queue addObject:obj];
    }else {
        [self removeObject];
        [_queue addObject:obj];
    }
    dispatch_semaphore_signal(_lock);
}

- (void)removeObject {
    NSMutableArray *array = [NSMutableArray array];
    
    for (int i = 0; i < _queue.count; i++) {
        AudioVideoFrame *frame = [_queue objectAtIndex:i];
        if ([frame isKindOfClass:[VideoFrame class]]) {
            VideoFrame *vf = (VideoFrame *)frame;
            if (vf.isKeyFrame && array.count > 0) {
                break;
            }else if (!vf.isKeyFrame) {
                [array addObject:vf];
            }
        }
    }
    
    if (array.count > 0) {
        [_queue removeObjectsInArray:array];
        return;
    }else {
        for (int i = 0; i < _queue.count; i++) {
            AudioVideoFrame *frame = [_queue objectAtIndex:i];
            if ([frame isKindOfClass:[VideoFrame class]]) {
                VideoFrame *vf = (VideoFrame *)frame;
                if (vf.isKeyFrame && array.count > 0) {
                    break;
                }else if (vf.isKeyFrame) {
                    [array addObject:vf];
                }
            }
        }
    }
    
    if (array.count > 0) {
        [_queue removeObjectsInArray:array];
    }else {
        [_queue removeAllObjects];
    }
}

- (AudioVideoFrame *)popObject {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    AudioVideoFrame *obj = nil;
    if (_queue.count > 0) {
        obj = _queue.firstObject;
        [_queue removeObjectAtIndex:0];
    }
    dispatch_semaphore_signal(_lock);
    return obj;
}

@end
