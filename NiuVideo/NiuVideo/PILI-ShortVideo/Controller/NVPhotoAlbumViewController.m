//
//  NVPhotoAlbumViewController.m
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/21.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "NVPhotoAlbumViewController.h"
#import "NVProcessVideoViewController.h"

#import "NVAlbumCollectionView.h"

@interface NVPhotoAlbumViewController ()
<
NVAlbumCollectionViewDelegate
>
@property (nonatomic, strong) NVAlbumCollectionView *albumCollectionView;
@property (assign, nonatomic) PHAssetMediaType mediaType;

@end

@implementation NVPhotoAlbumViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!NV_IPHONE_X) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    [self fetchAssetsWithMediaType:self.mediaType];
                } else {
                    [self showAlbumAlertMessage];
                }
            });
        }];
    } else if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusDenied) {
        [self showAlbumAlertMessage];
    } else {
        // authorized
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = NV_WHITE_COLOR;
    self.mediaType = PHAssetMediaTypeVideo;

    [self setupNavigationItem];
    [self setupAlbumCollectionView];
    
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
        [self fetchAssetsWithMediaType:self.mediaType];
    }
}

- (void)setupNavigationItem {
    
    if (_isEdit) {
        self.navigationItem.title = @"选择视频";

        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 52, 24)];
        [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 66, 24)];
        [saveButton setTitle:@"保存" forState:UIControlStateNormal];
        saveButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [saveButton setTitleColor:NV_BLACK_COLOR forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(enterNextAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    } else{
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 52, 24)];
        [backButton setImage:[UIImage imageNamed:@"go_back"] forState:UIControlStateNormal];
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        backButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [backButton setTitleColor:NV_BLACK_COLOR forState:UIControlStateNormal];
        [backButton setImageEdgeInsets:UIEdgeInsetsMake(0, -12, 0, 0)];
        [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
        [backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 66, 24)];
        [nextButton setImage:[UIImage imageNamed:@"next_step"] forState:UIControlStateNormal];
        [nextButton setTitle:@"下一步" forState:UIControlStateNormal];
        nextButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [nextButton setTitleColor:NV_BLACK_COLOR forState:UIControlStateNormal];
        [nextButton setImageEdgeInsets:UIEdgeInsetsMake(0, 57, 0, 0)];
        [nextButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -28, 0, 0)];
        [nextButton addTarget:self action:@selector(enterNextAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
        }
}

- (void)setupAlbumCollectionView {
    self.albumCollectionView = [[NVAlbumCollectionView alloc]initWithFrame:CGRectMake(0, NV_SAFE_TOP_HEIGHT_NAV, NV_SCREEN_WIDTH, NV_SCREEN_HEIGHT - NV_SAFE_TOP_HEIGHT_NAV)];
    self.albumCollectionView.delegate = self;
    [self.view addSubview:_albumCollectionView];
}

#pragma mark ---- NVAlbumCollectionViewDelegate ----
- (void)albumCollectionView:(NVAlbumCollectionView *)albumCollectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"--- NVAlbumCollectionViewDelegate ---");
}


#pragma mark - Assets
- (void)showAlbumAlertMessage {
    
}

- (void)fetchAssetsWithMediaType:(PHAssetMediaType)mediaType {
    __weak __typeof(self) weak = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.includeHiddenAssets = NO;
        fetchOptions.includeAllBurstAssets = NO;
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:mediaType options:fetchOptions];
        
        NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
        [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [mediaArray addObject:obj];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            weak.albumCollectionView.meidaArray = @[@{@"视频":mediaArray}];
        });
    });
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - button action

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)enterNextAction {
    NVProcessVideoViewController *processVideoVC = [[NVProcessVideoViewController alloc]init];
    [self.navigationController pushViewController:processVideoVC animated:YES];
}

- (void)closeButtonAction {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)saveEditAction {
    
}

#pragma mark ---- dealloc ----

- (void)dealloc {
    NSLog(@"dealloc: %@", [[self class] description]);
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
