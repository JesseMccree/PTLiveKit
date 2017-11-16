//
//  AudioManager.h
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioFrame.h"

@class AudioManager;

@protocol AudioManagerDelegate <NSObject>

- (void)audioManager:(AudioManager *)audioManager
          audioFrame:(AudioFrame *)audioFrame;

@end

@interface AudioManager : NSObject

@property (nonatomic, weak) id<AudioManagerDelegate> delegate;

- (id)initWithAudioConfig:(AudioConfig *)audioConfig;

- (void)encoderToAAC:(AudioBufferList )buffers;

@end
