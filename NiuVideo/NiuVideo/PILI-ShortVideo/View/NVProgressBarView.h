//
//  NVProgressBarView.h
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/12.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    NVProgressBarStyleNormal,
    NVProgressBarStyleDelete,
} NVProgressBarStyle;

@interface NVProgressBarView : UIView
- (instancetype)initWithFrame:(CGRect)frame intervalSpace:(CGFloat)intervalSpace;

- (void)setLastProgressByStyle:(NVProgressBarStyle)style;
- (void)setLastProgressByWidth:(CGFloat)width;

- (void)deleteLastProgressBar;
- (void)addProgressBarView;

- (void)startProgressAnimation;
- (void)stopProgressAnimation;
@end
