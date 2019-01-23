//
//  NVProgressBarView.m
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/12.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "NVProgressBarView.h"

#define NV_TIMER_INTERVAL 1.0f
@interface NVProgressBarView ()
@property (nonatomic, assign) CGFloat barHeight;
@property (nonatomic, strong) NSMutableArray *progressViewArray;
@property (nonatomic, strong) UIView *barView;
@property (nonatomic, strong) UIImageView *progressIndicator;
@property (nonatomic, strong) NSTimer *animationTimer;
@end

@implementation NVProgressBarView
- (instancetype)initWithFrame:(CGRect)frame intervalSpace:(CGFloat)intervalSpace {
    self = [super initWithFrame:frame];
    if (self) {
        _barHeight = frame.size.height;
        [self initalizeWithIntervalSpace:intervalSpace];
    }
    return self;
}

- (void)initalizeWithIntervalSpace:(CGFloat)intervalSpace {
    self.autoresizingMask = UIViewAutoresizingNone;
    self.backgroundColor = NV_PROGRESS_RECORD_BGCOLOR;
    self.progressViewArray = [[NSMutableArray alloc] init];
    
    // barView
    self.barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, _barHeight)];
    _barView.backgroundColor = NV_PROGRESS_RECORD_BGCOLOR;
    [self addSubview:_barView];
    
    // 最短分割线
    UIView *intervalView = [[UIView alloc] initWithFrame:CGRectMake(intervalSpace, 0, 1, _barHeight)];
    intervalView.backgroundColor = [UIColor blackColor];
    [_barView addSubview:intervalView];
                    
    // indicator
    self.progressIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 2, _barHeight)];
    _progressIndicator.backgroundColor = [UIColor clearColor];
    _progressIndicator.image = [UIImage imageNamed:@"progressbar_front.png"];
    [self addSubview:_progressIndicator];
}

- (UIView *)getProgressView {
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, _barHeight)];
    progressView.backgroundColor = NV_PROGRESS_RECORD_COLOR;
    progressView.autoresizesSubviews = YES;
    return progressView;
}

- (void)refreshIndicatorPosition {
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        _progressIndicator.center = CGPointMake(0, self.frame.size.height / 2);
        return;
    }
    _progressIndicator.center = CGPointMake(MIN(lastProgressView.frame.origin.x + lastProgressView.frame.size.width, self.frame.size.width - _progressIndicator.frame.size.width / 2 + 2), self.frame.size.height / 2);
}

- (void)onTimer:(NSTimer *)timer {
    [UIView animateWithDuration:NV_TIMER_INTERVAL / 2 animations:^{
        _progressIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:NV_TIMER_INTERVAL / 2 animations:^{
            _progressIndicator.alpha = 1;
        }];
    }];
}

#pragma mark -- method

- (void)startProgressAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:NV_TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

- (void)stopProgressAnimation {
    [_animationTimer invalidate];
    self.animationTimer = nil;
    _progressIndicator.alpha = 1;
}

- (void)addProgressBarView {
    UIView *lastProgressView = [_progressViewArray lastObject];
    CGFloat newProgressX = 0.0f;
    
    if (lastProgressView) {
        CGRect frame = lastProgressView.frame;
        frame.size.width -= 1;
        lastProgressView.frame = frame;
        newProgressX = frame.origin.x + frame.size.width + 1;
    }
    
    UIView *newProgressView = [self getProgressView];
    [self setView:newProgressView toOriginX:newProgressX];
    
    [_barView addSubview:newProgressView];
    [_progressViewArray addObject:newProgressView];
}

- (void)setLastProgressByWidth:(CGFloat)width {
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        return;
    }
    
    [self setView:lastProgressView toSizeWidth:width];
    [self refreshIndicatorPosition];
}

- (void)setLastProgressByStyle:(NVProgressBarStyle)style {
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        return;
    }
    
    switch (style) {
        case NVProgressBarStyleDelete:
        {
            lastProgressView.backgroundColor = [UIColor redColor];
            _progressIndicator.hidden = YES;
        }
            break;
        case NVProgressBarStyleNormal:
        {
            lastProgressView.backgroundColor = NV_PROGRESS_RECORD_BGCOLOR;
            _progressIndicator.hidden = NO;
        }
            break;
        default:
            break;
    }
}

- (void)deleteLastProgressBar {
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        return;
    }
    
    [lastProgressView removeFromSuperview];
    [_progressViewArray removeLastObject];
    
    _progressIndicator.hidden = NO;
    
    [self refreshIndicatorPosition];
}

- (void)setView:(UIView *)view toSizeWidth:(CGFloat)width {
    CGRect frame = view.frame;
    frame.size.width = width;
    view.frame = frame;
}

- (void)setView:(UIView *)view toOriginX:(CGFloat)x {
    CGRect frame = view.frame;
    frame.origin.x = x;
    view.frame = frame;
}

- (void)setView:(UIView *)view toOriginY:(CGFloat)y {
    CGRect frame = view.frame;
    frame.origin.y = y;
    view.frame = frame;
}

- (void)setView:(UIView *)view toOrigin:(CGPoint)origin {
    CGRect frame = view.frame;
    frame.origin = origin;
    view.frame = frame;
}

- (void)dealloc {
    _progressViewArray = nil;
    _barView = nil;
    _progressIndicator = nil;
    [_animationTimer invalidate];
    _animationTimer = nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
