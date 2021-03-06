//
//  APPRemindViewController.m
//  New_iwear
//
//  Created by JustFei on 2017/6/20.
//  Copyright © 2017年 manridy. All rights reserved.
//

#import "APPRemindViewController.h"
#import "APPRemindTableViewCell.h"

static NSString *const APPRemindTableViewCellID = @"APPRemindTableViewCell";

@interface APPRemindViewController () < UITableViewDelegate, UITableViewDataSource >

@property (nonatomic, strong) UITableView *appTableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation APPRemindViewController

- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"appRemind", nil);
    MDButton *leftButton = [[MDButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24) type:MDButtonTypeFlat rippleColor:nil];
    [leftButton setImageNormal:[UIImage imageNamed:@"ic_back"]];
    [leftButton addTarget:self action:@selector (backViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.view.backgroundColor = SETTING_BACKGROUND_COLOR;
    self.appTableView.backgroundColor = CLEAR_COLOR;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(setPairNoti:) name:GET_PAIR object:nil];
}

#pragma mark - Action
- (void)backViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveAction
{
    if ([BleManager shareInstance].connectState == kBLEstateDisConnected) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showTheStateBar];
    }else {
        Remind *model = [[Remind alloc] init];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PHONE_SWITCH_SETTING]) {
            model.phone = [[NSUserDefaults standardUserDefaults] boolForKey:PHONE_SWITCH_SETTING];
        }else {
            model.phone = NO;
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:MESSAGE_SWITCH_SETTING]) {
            model.message = [[NSUserDefaults standardUserDefaults] boolForKey:MESSAGE_SWITCH_SETTING];
        }else {
            model.message = NO;
        }
        model.wechat = ((APPRemindModel *)self.dataArr[0]).isSelect;
        model.qq = ((APPRemindModel *)self.dataArr[1]).isSelect;
        model.whatsApp = ((APPRemindModel *)self.dataArr[2]).isSelect;
        model.facebook = ((APPRemindModel *)self.dataArr[3]).isSelect;
        
        self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        self.hud.mode = MBProgressHUDModeIndeterminate;
        [[BleManager shareInstance] writePhoneAndMessageRemindToPeripheral:model];
    }
}

- (void)setPairNoti:(NSNotification *)noti
{
    [self.hud hideAnimated:YES];
    manridyModel *model = [noti object];
    if (model.isReciveDataRight) {
        MDToast *sucToast = [[MDToast alloc] initWithText:NSLocalizedString(@"saveSuccess", nil) duration:1.5];
        [sucToast show];
        [self saveSetting];
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        if (model.pairSuccess) {
            MDToast *sucToast = [[MDToast alloc] initWithText:NSLocalizedString(@"saveSuccess", nil) duration:1.5];
            [sucToast show];
            [self saveSetting];
            [self.navigationController popViewControllerAnimated:YES];
        }else {
            MDToast *sucToast = [[MDToast alloc] initWithText:NSLocalizedString(@"pairFail", nil) duration:3];
            [sucToast show];
            //保存选项至本地
            //[[NSUserDefaults standardUserDefaults] setBool:NO forKey:MESSAGE_SWITCH_SETTING];
        }
    }
}

- (void)saveSetting
{
    //保存选项至本地
    NSMutableArray *saveMutArr = [NSMutableArray array];
    for (APPRemindModel *model in self.dataArr) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
        [saveMutArr addObject:data];
    }
    //这里只能保存不可变数组，所以要转换
    NSArray *saveArr = [NSArray arrayWithArray:saveMutArr];
    [[NSUserDefaults standardUserDefaults] setObject:saveArr forKey:APP_REMIND_SETTING];
}

#pragma mark - UITableVIewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APPRemindTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:APPRemindTableViewCellID];
    APPRemindModel *model = self.dataArr[indexPath.row];
    cell.model = model;
    
    cell.appRemindSelectButtonClickBlock = ^(BOOL select) {
        model.isSelect = select;
        [self.dataArr replaceObjectAtIndex:indexPath.row withObject:model];
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    APPRemindModel *model = self.dataArr[indexPath.row];
    model.isSelect = !model.isSelect;
    [self.dataArr replaceObjectAtIndex:indexPath.row withObject:model];
    [tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}


#pragma mark - lazy
- (UITableView *)appTableView
{
    if (!_appTableView) {
        _appTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_appTableView registerClass:NSClassFromString(APPRemindTableViewCellID) forCellReuseIdentifier:APPRemindTableViewCellID];
        _appTableView.delegate = self;
        _appTableView.dataSource = self;
        _appTableView.tableFooterView = [UIView new];
        
        [self.view addSubview:_appTableView];
        [_appTableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_top);
            make.left.equalTo(self.view.mas_left);
            make.right.equalTo(self.view.mas_right);
            make.bottom.equalTo(self.view.mas_bottom);
        }];
    }
    
    return _appTableView;
}

- (NSMutableArray *)dataArr
{
    if (!_dataArr) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:APP_REMIND_SETTING]) {
            NSArray *arr = [[NSUserDefaults standardUserDefaults] objectForKey:APP_REMIND_SETTING];
            NSMutableArray *mutArr = [NSMutableArray array];
            for (NSData *data in arr) {
                APPRemindModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [mutArr addObject:model];
            }
            _dataArr = mutArr;
        }else {
            NSMutableArray *mutArr = [NSMutableArray array];
            NSArray *imageNameArr = @[@"appremind_wechat", @"appremind_qq", @"appremind_whatsapp", @"appremind_facebook"];
            NSArray *nameArr = @[NSLocalizedString(@"wechat", nil), @"QQ", @"WhatsApp", @"Facebook"];
            for (int index = 0; index < imageNameArr.count; index ++) {
                APPRemindModel *model = [[APPRemindModel alloc] init];
                model.imageName = imageNameArr[index];
                model.name = nameArr[index];
                model.isSelect = NO;
                [mutArr addObject:model];
            }
            _dataArr = mutArr;
        }
    }
    
    return _dataArr;
}

@end
