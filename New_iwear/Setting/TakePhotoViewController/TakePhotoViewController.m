//
//  TakePhotoViewController.m
//  New_iwear
//
//  Created by Faith on 2017/5/5.
//  Copyright © 2017年 manridy. All rights reserved.
//

#import "TakePhotoViewController.h"
#import "CameraViewController.h"

@interface TakePhotoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) MDButton *takePhotoButton;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@end

@implementation TakePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"RemoteControlCamera", nil);
    self.view.backgroundColor = SETTING_BACKGROUND_COLOR;
    
    [self createUI];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createUI
{
    MDButton *leftButton = [[MDButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24) type:MDButtonTypeFlat rippleColor:nil];
    [leftButton setImageNormal:[UIImage imageNamed:@"ic_back"]];
    [leftButton addTarget:self action:@selector(backViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    
    UILabel *infoLabel = [[UILabel alloc] init];
    [infoLabel setText:NSLocalizedString(@"usePerTakePhoto", nil)];
    [infoLabel setTextColor:TEXT_BLACK_COLOR_LEVEL3];
    [infoLabel setFont:[UIFont systemFontOfSize:14]];
    [self.view addSubview:infoLabel];
    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(16);
        make.top.equalTo(self.view.mas_top).offset(25 + 64);
    }];
    
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = TEXT_BLACK_COLOR_LEVEL1;
    [self.view addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.top.equalTo(infoLabel.mas_bottom).offset(18);
        make.height.equalTo(@1);
    }];
    
    self.takePhotoButton = [[MDButton alloc] initWithFrame:CGRectZero type:MDButtonTypeFlat rippleColor:nil];
    [self.takePhotoButton setImage:[UIImage imageNamed:@"camera_takephone01"] forState:UIControlStateNormal];
    [self.takePhotoButton setBackgroundColor:CLEAR_COLOR];
    [self.takePhotoButton addTarget:self action:@selector(takePhotoAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takePhotoButton];
    [self.takePhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(lineView.mas_bottom).offset(105);
        make.width.equalTo(@72);
        make.height.equalTo(@72);
    }];
    self.takePhotoButton.layer.masksToBounds = YES;
    self.takePhotoButton.layer.cornerRadius = 36;
    
    UILabel *takePhotoLabel = [[UILabel alloc] init];
    [takePhotoLabel setText:NSLocalizedString(@"startTakePhoto", nil)];
    [takePhotoLabel setFont:[UIFont systemFontOfSize:14]];
    [takePhotoLabel setTextColor:TEXT_BLACK_COLOR_LEVEL3];
    [self.view addSubview:takePhotoLabel];
    [takePhotoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.takePhotoButton.mas_bottom).offset(17.5);
    }];
}

#pragma mark - Action
- (void)backViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)takePhotoAction:(MDButton *)sender
{
    if ([BleManager shareInstance].connectState == kBLEstateDisConnected) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showTheStateBar];
    }else {
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(setTakePhoto:) name:SET_TAKE_PHOTO object:nil];
        [[BleManager shareInstance] writeCameraMode:kCameraModeOpenCamera];
        self.imagePicker = [[UIImagePickerController alloc]init];
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.showsCameraControls = NO;
        self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        //取景框全屏
        CGSize screenBounds = [UIScreen mainScreen].bounds.size;
        CGFloat cameraAspectRatio = 4.0f/3.0f;
        CGFloat camViewHeight = screenBounds.width * cameraAspectRatio;
        CGFloat scale = screenBounds.height / camViewHeight;
        self.imagePicker.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenBounds.height - camViewHeight) / 2.0);
        self.imagePicker.cameraViewTransform = CGAffineTransformScale(self.imagePicker.cameraViewTransform, scale, scale);
        self.imagePicker.delegate = self;
        
        //创建叠加层
        UIView *overLayView=[[UIView alloc]initWithFrame:self.imagePicker.view.bounds];
        
        //将视图设置为摄像头的叠加层
        self.imagePicker.cameraOverlayView = overLayView;
        
        //在叠加视图上自定义一个拍照按钮
        UIButton *takePhotoBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        [takePhotoBtn setImage:[UIImage imageNamed:@"camera_takephone02"] forState:UIControlStateNormal];
        [takePhotoBtn addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
        [overLayView addSubview:takePhotoBtn];
        [takePhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(overLayView.mas_centerX);
            make.bottom.equalTo(overLayView.mas_bottom).offset(-20);
        }];
        
        //再加一个翻转摄像头的按钮
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBtn setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [cancelBtn setTitleColor:WHITE_COLOR forState:UIControlStateNormal];
        [cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [overLayView addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(takePhotoBtn.mas_centerY);
            make.left.equalTo(overLayView.mas_left).offset(16);
        }];
        
        //页面跳转
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    }
    
    /** 由于自定义相机的优化不好，暂时先调用系统的 */
//    CameraViewController *vc = [[CameraViewController alloc] init];
//    [self.navigationController pushViewController:vc animated:YES];
}

//拍照
- (void)takePhoto:(UIButton *)sender
{
    [self.imagePicker takePicture];
}

//退出拍照
- (void)cancelAction:(UIButton *)sender
{
    [[BleManager shareInstance] writeCameraMode:kCameraModeCloseCamera];
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - observer
- (void)setTakePhoto:(NSNotification *)noti
{
    manridyModel *model = [noti object];
    if (model.takePhotoModel.takePhotoAction == YES) {
        [self.imagePicker takePicture];
    }
}

//PickerImage完成后的代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //定义一个newPhoto，用来存放我们选择的图片。
    UIImage *newPhoto = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [self saveImageToPhotoAlbum:newPhoto];
    //退出设备的相机模式
    [[BleManager shareInstance] writeCameraMode:kCameraModePhotoFinish];
    //关闭当前界面，即回到主界面去
//    [self dismissViewControllerAnimated:YES completion:nil];
//    
//    //调一下 cancel
//    [self takePhotoAction:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    //退出设备的相机模式
    [[BleManager shareInstance] writeCameraMode:kCameraModeCloseCamera];
}

#pragma - 保存至相册
- (void)saveImageToPhotoAlbum:(UIImage*)savedImage
{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

// 指定回调方法
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo

{
    NSString *msg = nil ;
    if(error != NULL){
        msg = NSLocalizedString(@"savePicFail", nil) ;
    }else{
        msg = NSLocalizedString(@"savePicSuccess", nil) ;
    }
    MDToast *toast = [[MDToast alloc] initWithText:msg duration:1.5];
    [toast show];
}

#pragma mark - lazy
//- (UIImagePickerController *)imagePicker
//{
//    if (!_imagePicker) {
//        _imagePicker = [[UIImagePickerController alloc]init];
//        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
//        _imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
//        _imagePicker.delegate = self;
//    }
//    
//    return _imagePicker;
//}

@end
