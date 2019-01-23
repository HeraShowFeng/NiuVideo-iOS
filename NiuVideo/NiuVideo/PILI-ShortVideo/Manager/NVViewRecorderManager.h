//
//  NVViewRecorderManager.h
//  NiuVideo
//
//  Created by lawder on 2017/7/13.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class NVViewRecorderManager;

@protocol NVViewRecorderManagerDelegate <NSObject>

@optional
- (void)viewRecorderManager:(NVViewRecorderManager *)manager didFinishRecordingToAsset:(AVAsset *)asset totalDuration:(CGFloat)totalDuration;
@end

@interface NVViewRecorderManager : NSObject

@property (weak, nonatomic) id<NVViewRecorderManagerDelegate> delegate;

- (instancetype)initWithRecordedView:(UIView *)recordedView;

- (void)startRecording;

- (void)stopRecording;

- (void)cancelRecording;

@end
