//
//  NVAlbumCollectionView.h
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/20.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
typedef enum {
    NVAlbumVideoType,
    NVAlbumImageType,
} NVAlbumMediaType;

@class NVAlbumCollectionView;
@protocol NVAlbumCollectionViewDelegate <NSObject>

@optional
/**
 albumCollectionView 选择 cell 的回调
 @param albumCollectionView NVAlbumCollectionView 的实例
 @param indexPath albumCollectionView被选中信息
 */
- (void)albumCollectionView:(NVAlbumCollectionView *)albumCollectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end
@interface NVAlbumCollectionView : UIView
@property (nonatomic, assign) id<NVAlbumCollectionViewDelegate> delegate;
@property (nonatomic, strong) NSArray<NSDictionary *> *meidaArray;
@property (nonatomic, strong) NSArray *selectedArray;

@end


@interface NVAlbumCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, strong) UIImageView *seletedImageView;

- (void)configureAlbumCollectionViewCellWithMediaType:(NVAlbumMediaType)mediaType  isSelected:(BOOL)isSelected;
@end
