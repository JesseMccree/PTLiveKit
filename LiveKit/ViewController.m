//
//  ViewController.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "ViewController.h"
#import "AudioVideoManager.h"

@interface ViewController () {
    UIButton          *recordVideoButton;
    AudioVideoManager *_manager;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    VideoConfig *videoConfig = [[VideoConfig alloc]init];
    videoConfig.fps = 24;
    videoConfig.width = 720;
    videoConfig.height = 1280;
    videoConfig.bitrate = 800*1024;
    
    AudioConfig *audioConfig = [[AudioConfig alloc]init];
    audioConfig.mSampleRate = 44100;
    audioConfig.mChannelsPerFrame = 2;
    
    _manager = [[AudioVideoManager alloc]initWithVideoConfig:videoConfig AudioConfig:audioConfig];
    [self.view addSubview:_manager.preView];
    
    recordVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordVideoButton.frame = CGRectMake(45, self.view.frame.size.height - 60 - 15, 60, 60);
    recordVideoButton.center = CGPointMake(self.view.frame.size.width / 2, recordVideoButton.frame.origin.y + recordVideoButton.frame.size.height / 2);
    [recordVideoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [recordVideoButton setTitle:@"直播" forState:UIControlStateNormal];
    recordVideoButton.selected = NO;
    [recordVideoButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [recordVideoButton setTitle:@"停止" forState:UIControlStateSelected];
    [recordVideoButton addTarget:self action:@selector(recordVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordVideoButton];
}

- (void)recordVideo:(UIButton *)button
{
    button.selected = !button.selected;
    
    if (button.selected) {
        
        [_manager start];
    }else {
        
        [_manager stop];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
