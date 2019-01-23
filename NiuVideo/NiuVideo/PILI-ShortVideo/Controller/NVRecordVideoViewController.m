//
//  NVRecordVideoViewController.m
//  NiuVideo
//
//  Created by 冯文秀 on 2017/12/12.
//  Copyright © 2017年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "NVRecordVideoViewController.h"
#import "NVProcessVideoViewController.h"
#import "NVPhotoAlbumViewController.h"

#import "NVViewRecorderManager.h"

#import "NVProgressBarView.h"
#import "NVSegmentButtonView.h"


#define NV_RECORD_Y_SPACE 64
#define NV_RECORD_BUTTON_WIDTH (80.f * NV_WIDTH_RATIO)

typedef enum {
    NVDeleteButtonStyleDelete,
    NVDeleteButtonStyleNormal,
    NVDeleteButtonStyleDisable,
} NVDeleteButtonStyle;

@interface NVRecordVideoViewController ()
<
PLShortVideoRecorderDelegate,
NVViewRecorderManagerDelegate,
NVSegmentButtonViewDelegate
>
@property (nonatomic, strong) PLShortVideoRecorder *shortVideoRecorder;
@property (nonatomic, strong) PLSVideoConfiguration *videoConfiguration;
@property (nonatomic, strong) PLSAudioConfiguration *audioConfiguration;

@property (nonatomic, strong) NVViewRecorderManager *viewRecorderManager;
@property (nonatomic, strong) NVProgressBarView *progressBar;
@property (nonatomic, strong) NVSegmentButtonView *segmentButtonView;
@property (strong, nonatomic) NSArray *titleArray;
@property (assign, nonatomic) NSInteger titleIndex;

// 录制前是否开启自动检测设备方向调整视频拍摄的角度（竖屏、横屏），默认开启
@property (nonatomic, assign) BOOL isUseAutoCheckDeviceOrientationBeforeRecording;

@property (nonatomic, strong) UIView *recordToolboxView;
// 录屏按钮
@property (nonatomic, strong) UIButton *viewRecordButton;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *faceButton;
@property (nonatomic, strong) UIButton *beautyButton;
@property (nonatomic, strong) UIButton *importButton;
@property (nonatomic, assign) NVDeleteButtonStyle deleteButtonStyle;

@property (nonatomic, strong) UIBarButtonItem *backBarButton;
@property (nonatomic, strong) UIBarButtonItem *setBarButton;

@end

@implementation NVRecordVideoViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = NV_WHITE_COLOR;

    [self setupNavigationItem];
    
    [self setupShortVideoRecorder];
    
    [self setupRecordToolboxView];
    
    self.isUseAutoCheckDeviceOrientationBeforeRecording = YES;
    
}

- (void)setupNavigationItem {
    self.navigationItem.title = @"录制视频";
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [backButton setImage:[UIImage imageNamed:@"drop_down"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *setButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [setButton setImage:[UIImage imageNamed:@"set_icon"] forState:UIControlStateNormal];
    [setButton addTarget:self action:@selector(setButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.backBarButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.setBarButton = [[UIBarButtonItem alloc] initWithCustomView:setButton];
    self.navigationItem.leftBarButtonItems = @[_backBarButton,_setBarButton];

    
    UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [flashButton setImage:[UIImage imageNamed:@"flash_light_close"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"flash_light_open"] forState:UIControlStateSelected];
    [flashButton addTarget:self action:@selector(flashButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [cameraButton setImage:[UIImage imageNamed:@"switch_camera"] forState:UIControlStateNormal];
    [cameraButton addTarget:self action:@selector(cameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *flashBarButton = [[UIBarButtonItem alloc] initWithCustomView:flashButton];
    UIBarButtonItem *cameraBarButton = [[UIBarButtonItem alloc] initWithCustomView:cameraButton];
    self.navigationItem.rightBarButtonItems = @[cameraBarButton,flashBarButton,];
}

- (void)setupRecordToolboxView {
    CGFloat y = NV_RECORD_Y_SPACE + NV_SCREEN_WIDTH;
    self.recordToolboxView = [[UIView alloc] initWithFrame:CGRectMake(0, y, NV_SCREEN_WIDTH, NV_SCREEN_HEIGHT - y)];
    self.recordToolboxView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.recordToolboxView];
    
    CGFloat intervalSpace = self.shortVideoRecorder.minDuration/self.shortVideoRecorder.maxDuration * NV_SCREEN_WIDTH;
    // 录制进度条
    self.progressBar = [[NVProgressBarView alloc]initWithFrame:CGRectMake(0, 0, NV_SCREEN_WIDTH, 5) intervalSpace:intervalSpace];
    [self.recordToolboxView addSubview:_progressBar];
    
    // 倍数按钮视图    
    self.titleArray = @[@"极慢", @"慢", @"正常", @"快", @"极快"];
    self.segmentButtonView = [[NVSegmentButtonView alloc]initWithFrame:CGRectMake(NV_SCREEN_WIDTH/2 - 130, 35, 260, 34) defaultIndex:2];
    self.segmentButtonView.hidden = NO;
    self.titleIndex = 2;
    CGFloat countSpace = 200 /self.titleArray.count / 6;
    self.segmentButtonView.space = countSpace;
    self.segmentButtonView.staticTitleArray = self.titleArray;
    self.segmentButtonView.rateDelegate = self;
    [self.recordToolboxView addSubview:_segmentButtonView];
    
    // 录制按钮
    NSInteger buttonWidth = (NSInteger)NV_RECORD_BUTTON_WIDTH;
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, buttonWidth)];
    self.recordButton.center = CGPointMake(NV_SCREEN_WIDTH / 2, self.recordToolboxView.frame.size.height - 80);
    CGFloat buttonRadius = (CGFloat)buttonWidth/2;
    self.recordButton.layer.cornerRadius = buttonRadius;
    self.recordButton.layer.borderColor = NV_BUTTON_RECORD_BORDER.CGColor;
    self.recordButton.layer.borderWidth = 8.f * NV_WIDTH_RATIO;
    self.recordButton.backgroundColor = NV_BLACK_COLOR;
    [self.recordButton setImage:[UIImage imageNamed:@"short_video_white"] forState:UIControlStateNormal];
    [self.recordButton addTarget:self action:@selector(recordButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordToolboxView addSubview:_recordButton];
    
    CGFloat centerY = self.recordButton.center.y - (buttonWidth/2 - 18);
    // 回删按钮
    self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(NV_SCREEN_WIDTH - 106, centerY, 34, 34)];
    self.deleteButton.backgroundColor = NV_BUTTON_GRAY_COLOR;
    self.deleteButton.layer.cornerRadius = 17;
    [self.deleteButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordToolboxView addSubview:_deleteButton];
    self.deleteButton.hidden = YES;
    self.deleteButtonStyle = NVDeleteButtonStyleNormal;
    
    // 结束录制按钮
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake(NV_SCREEN_WIDTH - 55, centerY, 34, 34)];
    self.nextButton.backgroundColor = NV_BUTTON_GRAY_COLOR;
    self.nextButton.layer.cornerRadius = 17;
    [self.nextButton setImage:[UIImage imageNamed:@"ready_yes"] forState:UIControlStateNormal];
    [self.nextButton setImage:[UIImage imageNamed:@"ready_no"] forState:UIControlStateDisabled];
    [self.nextButton addTarget:self action:@selector(nextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton.enabled = NO;
    [self.recordToolboxView addSubview:_nextButton];
    self.nextButton.hidden = YES;
    
    // 表情特效按钮
    self.faceButton = [[UIButton alloc] initWithFrame:CGRectMake(28 * NV_WIDTH_RATIO, centerY, 30, 42)];
    [self.faceButton addTarget:self action:@selector(faceButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordToolboxView addSubview:_faceButton];
    
    // 美颜按钮
    self.beautyButton = [[UIButton alloc] initWithFrame:CGRectMake(80 * NV_WIDTH_RATIO, centerY, 30, 42)];
    [self.beautyButton addTarget:self action:@selector(beautyButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordToolboxView addSubview:_beautyButton];
    
    // 导入视频按钮
    self.importButton = [[UIButton alloc] initWithFrame:CGRectMake(NV_SCREEN_WIDTH - 84, centerY, 30, 42)];
    [self.importButton addTarget:self action:@selector(importButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordToolboxView addSubview:_importButton];
    
    [self unifyButtonStyleWithButtons:@[self.faceButton, self.beautyButton, self.importButton]];
}

#pragma mark - method

- (void)unifyButtonStyleWithButtons:(NSArray *)buttons {
    NSArray *titleArray = @[@"表情", @"美颜", @"导入"];
    NSArray *imagesArray = @[@"face_check", @"face_beauty", @"import_movie"];
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIButton *button = buttons[i];
        [button setImage:[UIImage imageNamed:imagesArray[i]] forState:UIControlStateNormal];
        [button setTitle:titleArray[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11.f];
        [button setTitleColor:NV_BLACK_COLOR forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(0, 5, 16, 0)];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(28, -21, 0, 0)];
    }
}

// 短视频录制核心类设置
- (void)setupShortVideoRecorder {
    self.videoConfiguration = [PLSVideoConfiguration defaultConfiguration];
    self.videoConfiguration.position = AVCaptureDevicePositionFront;
    self.videoConfiguration.videoFrameRate = 25;
    self.videoConfiguration.averageVideoBitRate = 1024*1000;
    // 默认 1:1
    self.videoConfiguration.videoSize = CGSizeMake(480, 480);
    self.videoConfiguration.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    self.audioConfiguration = [PLSAudioConfiguration defaultConfiguration];
    
    self.shortVideoRecorder = [[PLShortVideoRecorder alloc] initWithVideoConfiguration:self.videoConfiguration audioConfiguration:self.audioConfiguration];
    self.shortVideoRecorder.delegate = self;
    self.shortVideoRecorder.minDuration = 2.0f; // 设置最短录制时长
    self.shortVideoRecorder.maxDuration = 10.0f; // 设置最长录制时长
    self.shortVideoRecorder.outputFileType = PLSFileTypeMPEG4;
    self.shortVideoRecorder.innerFocusViewShowEnable = YES; // 显示 SDK 内部自带的对焦动画
    self.shortVideoRecorder.previewView.frame = CGRectMake(0, NV_RECORD_Y_SPACE, NV_SCREEN_WIDTH, NV_SCREEN_WIDTH);
    [self.view addSubview:self.shortVideoRecorder.previewView];
    
    // 录制前是否开启自动检测设备方向调整视频拍摄的角度（竖屏、横屏）
    if (self.isUseAutoCheckDeviceOrientationBeforeRecording) {
        UIView *deviceOrientationView = [[UIView alloc] init];
        deviceOrientationView.frame = CGRectMake(0, 0, NV_SCREEN_WIDTH/2, 44);
        deviceOrientationView.center = CGPointMake(NV_SCREEN_WIDTH/2, 44/2);
        deviceOrientationView.backgroundColor = [UIColor grayColor];
        deviceOrientationView.alpha = 0.7;
        [self.view addSubview:deviceOrientationView];
        self.shortVideoRecorder.adaptationRecording = YES; // 根据设备方向自动确定横屏 or 竖屏拍摄效果
        [self.shortVideoRecorder setDeviceOrientationBlock:^(PLSPreviewOrientation deviceOrientation){
            switch (deviceOrientation) {
                case PLSPreviewOrientationPortrait:
                    NSLog(@"deviceOrientation : PLSPreviewOrientationPortrait");
                    break;
                case PLSPreviewOrientationPortraitUpsideDown:
                    NSLog(@"deviceOrientation : PLSPreviewOrientationPortraitUpsideDown");
                    break;
                case PLSPreviewOrientationLandscapeRight:
                    NSLog(@"deviceOrientation : PLSPreviewOrientationLandscapeRight");
                    break;
                case PLSPreviewOrientationLandscapeLeft:
                    NSLog(@"deviceOrientation : PLSPreviewOrientationLandscapeLeft");
                    break;
                default:
                    break;
            }
            
            if (deviceOrientation == PLSPreviewOrientationPortrait) {
                deviceOrientationView.frame = CGRectMake(0, 0, NV_SCREEN_WIDTH/2, 44);
                deviceOrientationView.center = CGPointMake(NV_SCREEN_WIDTH/2, 44/2);
                
            } else if (deviceOrientation == PLSPreviewOrientationPortraitUpsideDown) {
                deviceOrientationView.frame = CGRectMake(0, 0, NV_SCREEN_WIDTH/2, 44);
                deviceOrientationView.center = CGPointMake(NV_SCREEN_WIDTH/2, NV_SCREEN_HEIGHT - 44/2);
                
            } else if (deviceOrientation == PLSPreviewOrientationLandscapeRight) {
                deviceOrientationView.frame = CGRectMake(0, 0, 44, NV_SCREEN_HEIGHT/2);
                deviceOrientationView.center = CGPointMake(NV_SCREEN_WIDTH - 44/2, NV_SCREEN_HEIGHT/2);
                
            } else if (deviceOrientation == PLSPreviewOrientationLandscapeLeft) {
                deviceOrientationView.frame = CGRectMake(0, 0, 44, NV_SCREEN_HEIGHT/2);
                deviceOrientationView.center = CGPointMake(44/2, NV_SCREEN_HEIGHT/2);
            }
        }];
    }
}

#pragma mark - button action

- (void)backButtonAction:(UIButton *)backButton {
    if (self.viewRecordButton.isSelected) {
        [self.viewRecorderManager cancelRecording];
    }
    if ([self.shortVideoRecorder getFilesCount] > 0) {
        // 提示是否放弃录制的视频
        [self.shortVideoRecorder cancelRecording];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.shortVideoRecorder cancelRecording];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// 录制相关设置
- (void)setButtonAction:(UIButton *)setButton {
    
}

// 打开／关闭闪光灯
- (void)flashButtonAction:(UIButton *)flashButton {
    if (self.shortVideoRecorder.torchOn) {
        self.shortVideoRecorder.torchOn = NO;
        flashButton.selected = NO;
    } else {
        self.shortVideoRecorder.torchOn = YES;
        flashButton.selected = YES;
    }
}

// 切换摄像头
- (void)cameraButtonAction:(UIButton *)cameraButton {
    [self.shortVideoRecorder toggleCamera];
}

// 录制／暂停
- (void)recordButtonAction:(UIButton *)recordButton {
    if (self.shortVideoRecorder.isRecording) {
        [self.shortVideoRecorder stopRecording];
    } else {
        [self.shortVideoRecorder startRecording];
    }
}

// 录屏
- (void)viewRecordButtonAction:(UIButton *)viewRecordButton {
    if (!self.viewRecorderManager) {
        self.viewRecorderManager = [[NVViewRecorderManager alloc] initWithRecordedView:self.view];
        self.viewRecorderManager.delegate = self;
    }
    
    if (self.viewRecordButton.isSelected) {
        self.viewRecordButton.selected = NO;
        [self.viewRecorderManager stopRecording];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    }
    else {
        self.viewRecordButton.selected = YES;
        [self.viewRecorderManager startRecording];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
}

// 回删
- (void)deleteButtonAction:(UIButton *)deleteButton {
    if (_deleteButtonStyle == NVDeleteButtonStyleNormal) {
        [_progressBar setLastProgressByStyle:NVProgressBarStyleDelete];
        _deleteButtonStyle = NVDeleteButtonStyleDelete;
    } else if (_deleteButtonStyle == NVDeleteButtonStyleDelete) {
        [self.shortVideoRecorder deleteLastFile];
        [_progressBar deleteLastProgressBar];
        _deleteButtonStyle = NVDeleteButtonStyleNormal;
    }
}

// 下一步
- (void)nextButtonAction:(UIButton *)nextButton {
    AVAsset *asset = self.shortVideoRecorder.assetRepresentingAllFiles;
    [self enterProcessVideoViewWithAsset:asset];
    [self.viewRecorderManager cancelRecording];
    self.viewRecordButton.selected = NO;
}

// 特效
- (void)faceButtonAction:(UIButton *)faceButton {
    
}

// 美颜
- (void)beautyButtonAction:(UIButton *)beautyButton {
    beautyButton.selected = !beautyButton.selected;
    [self.shortVideoRecorder setBeautifyModeOn:beautyButton.selected];
}

- (void)importButtonAction:(UIButton *)importButton {
    NVPhotoAlbumViewController *photoAlbumVC = [[NVPhotoAlbumViewController alloc]init];
    photoAlbumVC.isEdit = NO;
    [self.navigationController pushViewController:photoAlbumVC animated:YES];
}

- (void)enterProcessVideoViewWithAsset:(AVAsset *)asset {;
    NSArray *filesURLArray = [self.shortVideoRecorder getAllFilesURL];
    NSLog(@"filesURLArray:%@", filesURLArray);
    
    __block AVAsset *movieAsset = asset;
    
    NVProcessVideoViewController *processVideoVC = [[NVProcessVideoViewController alloc] init];
    [self.navigationController pushViewController:processVideoVC animated:YES];
}

- (void)segmentButtonView:(NVSegmentButtonView *)segmentButtonView didSelectedTitleIndex:(NSInteger)titleIndex {
    self.titleIndex = titleIndex;
    switch (titleIndex) {
        case 0:
            self.shortVideoRecorder.recoderRate = PLSVideoRecoderRateTopSlow;
            break;
        case 1:
            self.shortVideoRecorder.recoderRate = PLSVideoRecoderRateSlow;
            break;
        case 2:
            self.shortVideoRecorder.recoderRate = PLSVideoRecoderRateNormal;
            break;
        case 3:
            self.shortVideoRecorder.recoderRate = PLSVideoRecoderRateFast;
            break;
        case 4:
            self.shortVideoRecorder.recoderRate = PLSVideoRecoderRateTopFast;
            break;
        default:
            break;
    }
}

#pragma mark - PLSViewRecorderManagerDelegate
- (void)viewRecorderManager:(NVViewRecorderManager *)manager didFinishRecordingToAsset:(AVAsset *)asset totalDuration:(CGFloat)totalDuration {
    self.viewRecordButton.selected = NO;
    // 设置音视频、水印等编辑信息
    NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
    // 待编辑的原始视频素材
    NSMutableDictionary *plsMovieSettings = [[NSMutableDictionary alloc] init];
    plsMovieSettings[PLSAssetKey] = asset;
    plsMovieSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:0.f];
    plsMovieSettings[PLSDurationKey] = [NSNumber numberWithFloat:totalDuration];
    plsMovieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:1.0f];
    outputSettings[PLSMovieSettingsKey] = plsMovieSettings;
    
    NVProcessVideoViewController *processVideoVC = [[NVProcessVideoViewController alloc] init];
    [self.navigationController pushViewController:processVideoVC animated:YES];
}

#pragma mark -- PLShortVideoRecorderDelegate 摄像头／麦克风鉴权的回调
- (void)shortVideoRecorder:(PLShortVideoRecorder *__nonnull)recorder didGetCameraAuthorizationStatus:(PLSAuthorizationStatus)status {
    if (status == PLSAuthorizationStatusAuthorized) {
        [recorder startCaptureSession];
    }
    else if (status == PLSAuthorizationStatusDenied) {
        NSLog(@"Error: user denies access to camera");
    }
}

- (void)shortVideoRecorder:(PLShortVideoRecorder *__nonnull)recorder didGetMicrophoneAuthorizationStatus:(PLSAuthorizationStatus)status {
    if (status == PLSAuthorizationStatusAuthorized) {
        [recorder startCaptureSession];
    }
    else if (status == PLSAuthorizationStatusDenied) {
        NSLog(@"Error: user denies access to microphone");
    }
}

#pragma mark - PLShortVideoRecorderDelegate 摄像头对焦位置的回调
- (void)shortVideoRecorderDidFocusAtPoint:(CGPoint)point {
    NSLog(@"shortVideoRecorderDidFocusAtPoint:%@", NSStringFromCGPoint(point));
}

#pragma mark - PLShortVideoRecorderDelegate 摄像头采集的视频数据的回调
/// @abstract 获取到摄像头原数据时的回调, 便于开发者做滤镜等处理，需要注意的是这个回调在 camera 数据的输出线程，请不要做过于耗时的操作，否则可能会导致帧率下降
- (CVPixelBufferRef)shortVideoRecorder:(PLShortVideoRecorder *)recorder cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    UIDeviceOrientation recordDeviceOrientation = [[UIDevice currentDevice] orientation];
    BOOL mirrored = NO;
    return pixelBuffer;
}

#pragma mark -- PLShortVideoRecorderDelegate 视频录制回调

// 开始录制一段视频时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didStartRecordingToOutputFileAtURL:(NSURL *)fileURL {
    NSLog(@"start recording fileURL: %@", fileURL);
    
    [self.progressBar addProgressBarView];
    [_progressBar startProgressAnimation];
}

// 正在录制的过程中
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    [_progressBar setLastProgressByWidth:fileDuration / self.shortVideoRecorder.maxDuration * _progressBar.frame.size.width];
    
    self.nextButton.enabled = (totalDuration >= self.shortVideoRecorder.minDuration);
    
    self.deleteButton.hidden = YES;
    self.nextButton.hidden = YES;
    self.importButton.hidden = YES;
    self.navigationItem.leftBarButtonItems = @[_backBarButton];
    //    self.durationLabel.text = [NSString stringWithFormat:@"%.2fs", totalDuration];
}

// 删除了某一段视频
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didDeleteFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    NSLog(@"delete fileURL: %@, fileDuration: %f, totalDuration: %f", fileURL, fileDuration, totalDuration);
    
    self.nextButton.enabled = (totalDuration >= self.shortVideoRecorder.minDuration);
    
    if (totalDuration <= 0.0000001f) {
        self.deleteButton.hidden = YES;
        self.nextButton.hidden = YES;
        self.importButton.hidden = NO;
        self.navigationItem.leftBarButtonItems = @[_backBarButton, _setBarButton];
    }
    //    self.durationLabel.text = [NSString stringWithFormat:@"%.2fs", totalDuration];
}

// 完成一段视频的录制时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    NSLog(@"finish recording fileURL: %@, fileDuration: %f, totalDuration: %f", fileURL, fileDuration, totalDuration);
    
    [_progressBar stopProgressAnimation];
    
    self.nextButton.enabled = (totalDuration >= self.shortVideoRecorder.minDuration);
    self.deleteButton.hidden = NO;
    self.nextButton.hidden = NO;
    
    if (totalDuration >= self.shortVideoRecorder.maxDuration) {
        [self nextButtonAction:nil];
    }
}

// 在达到指定的视频录制时间 maxDuration 后，如果再调用 [PLShortVideoRecorder startRecording]，直接执行该回调
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingMaxDuration:(CGFloat)maxDuration {
    NSLog(@"finish recording maxDuration: %f", maxDuration);
    
    AVAsset *asset = self.shortVideoRecorder.assetRepresentingAllFiles;
    [self enterProcessVideoViewWithAsset:asset];
    [self.viewRecorderManager cancelRecording];
    self.viewRecordButton.selected = NO;
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
