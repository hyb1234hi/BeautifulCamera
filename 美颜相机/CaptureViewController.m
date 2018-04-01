//
//  CaptureViewController.m
//  美颜相机
//
//  Created by ireliad on 2018/3/31.
//  Copyright © 2018年 正辰科技. All rights reserved.
//

#import "CaptureViewController.h"
#import <Masonry/Masonry.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^PropertyChangeBlock) (AVCaptureDevice * captureDevice);

/**
 https://www.jianshu.com/p/0174844dda75
 */
@interface CaptureViewController ()<AVCapturePhotoCaptureDelegate>

///负责输入和输出设备之间的数据传输
@property (nonatomic, strong) AVCaptureSession * captureSession;
///负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureDeviceInput * captureDeviceInput;
///照片输出流
@property (nonatomic, strong) AVCapturePhotoOutput * capturePhotoOutput;
///后台任务标识
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
///相机拍摄预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * captureVideoPreviewLayer;

@property(nonatomic,strong)UIView *contentView;
@property(nonatomic,strong)UIButton *cancelBtn;
@property(nonatomic,strong)UIButton *photoBtn;
@property(nonatomic,strong)UIButton *sizeBtn;
@property(nonatomic,strong)UIButton *moreBtn;
@property(nonatomic,strong)UIButton *transformBtn;
@property(nonatomic,strong)UIButton *cameraBtn;
@property(nonatomic,strong)UIButton *filterBtn;
@property(nonatomic,strong)UIImageView *focusImageView;

@end

@implementation CaptureViewController

#pragma mark - 📓public method

#pragma mark - 📒life cycle
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self initCamera];
    [self addGenstureRecognizer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - 📕delegate
#pragma mark - AVCapturePhotoCaptureDelegate
-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"拍照失败" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil] show];
        return;
    }
    
    NSData *imageData = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:imageData];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"已保存到系统相册中" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil] show];
}

#pragma mark - 📗event response
-(void)cameraBtnClick:(UIButton*)btn
{
    [self.capturePhotoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
}

-(void)cancelBtnClick:(UIButton*)btn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)photoBtnClick:(UIButton*)btn
{
    UIImagePickerController *pickerCtrl = [[UIImagePickerController alloc] init];
    pickerCtrl.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:pickerCtrl animated:YES completion:nil];
}

-(void)sizeBtnClick:(UIButton*)btn
{
    
}

-(void)moreBtnClick:(UIButton*)btn
{
    AVCaptureDevice *device = self.captureDeviceInput.device;
    
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            device.torchMode = AVCaptureTorchModeOn;
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeOff;
            device.torchMode = AVCaptureTorchModeOff;
        }
        
    }
    [device unlockForConfiguration];
}

-(void)transformBtnClick:(UIButton*)btn
{
    AVCaptureDevice * currentDevice = [self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    AVCaptureDevice * toChangeDevice;
    AVCaptureDevicePosition  toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    } else {
        toChangePosition = AVCaptureDevicePositionFront;
    }
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    
    //获得要调整到设备输入对象
    AVCaptureDeviceInput * toChangeDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    //改变会话到配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    //移除原有输入对象
    [self.captureSession removeInput:self.captureDeviceInput];
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        _captureDeviceInput=toChangeDeviceInput;
    }
    
    //提交新的输入对象
    [self.captureSession commitConfiguration];
    
}

- (void)tapScreen:(UITapGestureRecognizer *) tapGesture{
    
    CGPoint point = [tapGesture locationInView:self.contentView];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
//    point.y +=124;
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

#pragma mark - 📘private method
-(void)initUI
{
    [self contentView];
    [self cancelBtn];
    [self photoBtn];
    [self sizeBtn];
    [self moreBtn];
    [self transformBtn];
    [self cameraBtn];
    [self filterBtn];
    [self focusImageView];
    
    NSArray<UIButton *> *btns = @[self.cancelBtn, self.photoBtn, self.sizeBtn, self.moreBtn, self.transformBtn];
    [btns mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(30);
    }];
    [btns mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedItemLength:30 leadSpacing:25 tailSpacing:25];
}

-(void)initCamera
{
    [self captureSession];
    [self captureDeviceInput];
    [self capturePhotoOutput];
    [self captureVideoPreviewLayer];
}

//获取指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition) position{
    AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray *devicesIOS  = devicesIOS10.devices;
    for (AVCaptureDevice *device in devicesIOS) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

//添加点击手势，点按时聚焦
- (void)addGenstureRecognizer{
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    [self.contentView addGestureRecognizer:tapGesture];
}

//设置聚焦光标位置
- (void)setFocusCursorWithPoint:(CGPoint)point{
    
    self.focusImageView.center = point;
    self.focusImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusImageView.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusImageView.alpha=0;
    }];
}

//设置聚焦点
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

//输入设备属性改变操作
- (void)changeDeviceProperty:(PropertyChangeBlock ) propertyChange{
    
    AVCaptureDevice * captureDevice = [self.captureDeviceInput device];
    NSError * error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        
    } else {
        
        NSLog(@"设置设备属性过程发生错误，错误信息：%@", error.localizedDescription);
    }
}

//设置闪光灯模式
- (void)setFlashMode:(AVCaptureFlashMode ) flashMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        
        if ([captureDevice isFlashModeSupported:flashMode]) {
            [captureDevice setFlashMode:flashMode];
        }
    }];
}
#pragma mark - 📙getter and setter
-(UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        [self.view addSubview:_contentView];
        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _contentView;
}

-(UIButton *)cameraBtn
{
    if (!_cameraBtn) {
        _cameraBtn = [UIButton new];
        [_cameraBtn setImage:[UIImage imageNamed:@"icon_camera"] forState:UIControlStateNormal];
        [self.view addSubview:_cameraBtn];
        [_cameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-38);
        }];
        
        [_cameraBtn addTarget:self action:@selector(cameraBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraBtn;
}

-(UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton new];
        [_cancelBtn setImage:[UIImage imageNamed:@"icon_cancel"] forState:UIControlStateNormal];
        [self.view addSubview:_cancelBtn];
        
        [_cancelBtn addTarget:self action:@selector(cancelBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

-(UIButton *)photoBtn
{
    if (!_photoBtn) {
        _photoBtn = [UIButton new];
        [_photoBtn setImage:[UIImage imageNamed:@"icon_image"] forState:UIControlStateNormal];
        [self.view addSubview:_photoBtn];
        
        [_photoBtn addTarget:self action:@selector(photoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoBtn;
}

-(UIButton *)sizeBtn
{
    if (!_sizeBtn) {
        _sizeBtn = [UIButton new];
        [_sizeBtn setImage:[UIImage imageNamed:@"icon_size"] forState:UIControlStateNormal];
        [self.view addSubview:_sizeBtn];
        
        [_sizeBtn addTarget:self action:@selector(sizeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sizeBtn;
}

-(UIButton *)moreBtn
{
    if (!_moreBtn) {
        _moreBtn = [UIButton new];
        [_moreBtn setImage:[UIImage imageNamed:@"icon_more"] forState:UIControlStateNormal];
        [self.view addSubview:_moreBtn];
        
        [_moreBtn addTarget:self action:@selector(moreBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreBtn;
}

-(UIButton *)transformBtn
{
    if (!_transformBtn) {
        _transformBtn = [UIButton new];
        [_transformBtn setImage:[UIImage imageNamed:@"icon_transform"] forState:UIControlStateNormal];
        [self.view addSubview:_transformBtn];
        
        [_transformBtn addTarget:self action:@selector(transformBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _transformBtn;
}

-(UIImageView *)focusImageView
{
    if (!_focusImageView) {
        _focusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_focus"]];
        [self.contentView addSubview:_focusImageView];
        [_focusImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentView);
        }];
        
        _focusImageView.alpha = 0.0;
    }
    return _focusImageView;
}

-(AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        //设置分辨率
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
    }
    return _captureSession;
}

-(AVCaptureDeviceInput *)captureDeviceInput
{
    if (!_captureDeviceInput) {
        //获得输入设备
        AVCaptureDevice * captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        
        NSError *error = nil;
        _captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
        NSAssert(error == nil, @"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        
        //添加到session中
        if ([self.captureSession canAddInput:_captureDeviceInput]) {
            [self.captureSession addInput:_captureDeviceInput];
        }
    }
    return _captureDeviceInput;
}

-(AVCapturePhotoOutput *)capturePhotoOutput
{
    if (!_capturePhotoOutput) {
        _capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
//        NSDictionary * outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
//        //输出设置
//        [_captureStillImageOutput setOutputSettings:outputSettings];
//
//        //添加到session中
//        if ([self.captureSession canAddOutput:_captureStillImageOutput]) {
//            [self.captureSession addOutput:_captureStillImageOutput];
//        }

        //添加到session中
        if ([self.captureSession canAddOutput:_capturePhotoOutput]) {
            [self.captureSession addOutput:_capturePhotoOutput];
        }
        
    }
    return _capturePhotoOutput;
}

-(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer
{
    if (!_captureVideoPreviewLayer) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        CALayer * layer = self.contentView.layer;
        layer.masksToBounds = YES;
        
        _captureVideoPreviewLayer.frame = [UIScreen mainScreen].bounds;
        //填充模式
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        //将视频预览层添加到界面中
        [layer insertSublayer:_captureVideoPreviewLayer below:self.focusImageView.layer];
    }
    return _captureVideoPreviewLayer;
}
@end
