//
//  RtmpManager.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RtmpManager : NSObject

- (BOOL)rtmpConnect:(NSString *)url;

- (void)rtmpClose;

- (void)sendAVCCSps:(NSData *)sps
                Pps:(NSData *)pps;

- (void)sendAVCFrame:(NSData *)frame
          isKeyFrame:(BOOL)isKeyFrame;

- (void)sendAACSpec:(NSData *)spec;

- (void)sendAACFrame:(NSData *)frame;

@end
