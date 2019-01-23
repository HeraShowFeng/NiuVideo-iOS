//
//  NVAlbumCollectionView.m
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/20.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "NVAlbumCollectionView.h"

static NSString *const itemIdentifier = @"ablumItem";

@interface NVAlbumCollectionView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation NVAlbumCollectionView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedArray = [NSMutableArray array];
        [self setupAlbumCollectionView];
    }
    return self;
}

- (void)setMeidaArray:(NSArray<NSDictionary *> *)meidaArray {
    _meidaArray = meidaArray;
    [self.collectionView reloadData];
}

- (void)setupAlbumCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat w = (NV_SCREEN_WIDTH / 4) - 1;
    layout.itemSize = CGSizeMake(w, w);
    layout.minimumInteritemSpacing = 1.0;
    layout.minimumLineSpacing = 1.0;
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, NV_SCREEN_WIDTH, CGRectGetHeight(self.frame)) collectionViewLayout:layout];
    self.collectionView.backgroundColor = NV_WHITE_COLOR;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[NVAlbumCollectionViewCell class] forCellWithReuseIdentifier:itemIdentifier];
    [self addSubview:_collectionView];
}

#pragma mark - collectionView delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _meidaArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_meidaArray.count != 0) {
        NSDictionary *dictionary = _meidaArray[section];
        return [dictionary.allValues[0] count];
    } else{
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NVAlbumCollectionViewCell *item = (NVAlbumCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:itemIdentifier forIndexPath:indexPath];
   
    if (_meidaArray.count > 1) {
        NSDictionary *dictionary = _meidaArray[indexPath.section];
        NSArray *array = dictionary.allValues[0];
        id element = array[indexPath.row];
        
        BOOL isSelected = NO;
        if ([_selectedArray containsObject:element]) {
            isSelected = YES;
        }
        
        if ([element isKindOfClass:[PHAsset class]]) {
            item.asset = (PHAsset *)element;
            [item configureAlbumCollectionViewCellWithMediaType:NVAlbumVideoType isSelected:isSelected];
        } else{
            item.imageView.image = (UIImage *)element;
            [item configureAlbumCollectionViewCellWithMediaType:NVAlbumImageType isSelected:isSelected];
        }
    }
    return item;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(albumCollectionView:didSelectItemAtIndexPath:)]) {
        [self.delegate albumCollectionView:self didSelectItemAtIndexPath:indexPath];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *headReusableView;
    return headReusableView;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@implementation NVAlbumCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageRequestID = PHInvalidImageRequestID;
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];
        
        self.seletedImageView = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetWidth(frame) - 22, 2, 20, 20)];
        self.seletedImageView.image = [UIImage imageNamed:@""];
        self.seletedImageView.hidden = YES;
        self.seletedImageView.center = self.center;
        [self.imageView addSubview:_seletedImageView];
    }
    return self;
}

- (void)configureAlbumCollectionViewCellWithMediaType:(NVAlbumMediaType)mediaType isSelected:(BOOL)isSelected {
    if (isSelected) {
        self.seletedImageView.hidden = NO;
    } else{
        self.seletedImageView.hidden = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.imageView.bounds = self.bounds;
}

- (void)prepareForReuse {
    [self cancelImageRequest];
    self.imageView.image = nil;
}

- (void)cancelImageRequest {
    if (self.imageRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        self.imageRequestID = PHInvalidImageRequestID;
    }
}

- (void)setAsset:(PHAsset *)asset {
    if (_asset != asset) {
        _asset = asset;
        
        [self cancelImageRequest];
        
        if (_asset) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            CGFloat scale = [UIScreen mainScreen].scale;
            CGSize size = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
            self.imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                if (_asset == asset) {
                    self.imageView.image = result;
                }
             }];
        }
    }
}

@end
