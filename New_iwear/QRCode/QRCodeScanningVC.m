//
//  QRCodeScanningVC.m
//  SGQRCodeExample
//
//  Created by apple on 17/3/21.
//  Copyright © 2017年 JP_lee. All rights reserved.
//

#import "QRCodeScanningVC.h"
//#import "ScanSuccessJumpVC.h"

@interface QRCodeScanningVC ()

@property (nonatomic ,strong) UIAlertController *alert;

@end

@implementation QRCodeScanningVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 注册观察者
    [SGQRCodeNotificationCenter addObserver:self selector:@selector(SGQRCodeInformationFromeAibum:) name:SGQRCodeInformationFromeAibum object:nil];
    [SGQRCodeNotificationCenter addObserver:self selector:@selector(SGQRCodeInformationFromeScanning:) name:SGQRCodeInformationFromeScanning object:nil];
}

//从相册获取
- (void)SGQRCodeInformationFromeAibum:(NSNotification *)noti {
    NSString *string = noti.object;
    self.alert = [UIAlertController alertControllerWithTitle:@"扫描到的信息" message:string preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAC = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //退出扫描页面
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *contentAC = [UIAlertAction actionWithTitle:@"连接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //连接设备
        self.scanResult(string);
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [self.alert addAction:cancelAC];
    [self.alert addAction:contentAC];
    [self presentViewController:self.alert animated:YES completion:nil];
}

//从取景器获取
- (void)SGQRCodeInformationFromeScanning:(NSNotification *)noti {
    SGQRCodeLog(@"noti - - %@", noti);
    NSString *string = noti.object;
    self.alert = [UIAlertController alertControllerWithTitle:@"扫描到的信息" message:string preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAC = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //退出扫描页面
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *contentAC = [UIAlertAction actionWithTitle:@"连接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //连接设备
        if (self.scanResult) {
            self.scanResult(string);
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [self.alert addAction:cancelAC];
    [self.alert addAction:contentAC];
    
    [self presentViewController:self.alert animated:YES completion:nil];
}

- (void)dealloc {
    SGQRCodeLog(@"QRCodeScanningVC - dealloc");
    [SGQRCodeNotificationCenter removeObserver:self];
}

@end