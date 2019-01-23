//
//  NVSegmentButtonView.h
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/20.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NVSegmentButtonView;
@protocol NVSegmentButtonViewDelegate <NSObject>

- (void)segmentButtonView:(NVSegmentButtonView *)segmentButtonView didSelectedTitleIndex:(NSInteger)titleIndex;

@end

@interface NVSegmentButtonView : UIView

@property (nonatomic, strong) NSArray *staticTitleArray;
@property (nonatomic, strong) NSArray *scrollTitleArr;

@property (nonatomic, strong) NSMutableArray *totalLabelArray;

@property (nonatomic, assign) id<NVSegmentButtonViewDelegate> rateDelegate;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) CGFloat space;


- (instancetype)initWithFrame:(CGRect)frame defaultIndex:(NSInteger)defaultIndex;
@end
