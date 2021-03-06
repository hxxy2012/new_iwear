//
//  UserInfoViewController.m
//  ManridyApp
//
//  Created by JustFei on 16/9/28.
//  Copyright © 2016年 Manridy.Bobo.com. All rights reserved.
//

#import "UserInfoViewController.h"
#import "UserInfoTableViewCell.h"
#import "FMDBManager.h"
#import "BleManager.h"
#import "UserInfoModel.h"
#import "UserInfoSettingModel.h"
#import "UnitsTool.h"

typedef enum : NSUInteger {
    PickerTypeGender = 0,
    PickerTypeAge,
    PickerTypeHeight,
    PickerTypeWeight,
} PickerType;

static NSString * const UserInfoTableViewCellID = @"UserInfoTableViewCell";

@interface UserInfoViewController () <UITableViewDelegate ,UITableViewDataSource ,UITextFieldDelegate ,UINavigationControllerDelegate ,UIImagePickerControllerDelegate ,UIAlertViewDelegate ,UIPickerViewDelegate ,UIPickerViewDataSource>

@property (nonatomic, weak) UIImageView *headImageView;
@property (nonatomic, weak) UITextField *userNameTextField;
@property (nonatomic, weak) UITableView *infoTableView;
@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, assign) BOOL isMetric;
@property (nonatomic, assign) PickerType pickerType;
@property (nonatomic, strong) UIPickerView *infoPickerView;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSArray *genderArr;
@property (nonatomic, strong) NSArray *ageArr;
@property (nonatomic, strong) NSArray *heightArr;
@property (nonatomic, strong) NSArray *weightArr;
@property (nonatomic, strong) UserInfoModel *infoModel;

@end

@implementation UserInfoViewController

#pragma mark - lyfeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isMetric = [self isMetricOrImperialSystem];
    self.navigationItem.title = NSLocalizedString(@"userInfo", nil);
    self.view.backgroundColor = SETTING_BACKGROUND_COLOR;
    
    self.userNameTextField.borderStyle = UITextBorderStyleNone;
    self.userNameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    //监听写入的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUserInfoWhetherSuccess:) name:SET_USER_INFO object:nil];
    
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = TEXT_BLACK_COLOR_LEVEL1;
    [self.view addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userNameTextField.mas_bottom).offset(16);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.height.equalTo(@8);
    }];
    
    [self.infoTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView.mas_bottom);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
    }];
    
    self.title = NSLocalizedString(@"userInfo", nil);
    MDButton *leftButton = [[MDButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24) type:MDButtonTypeFlat rippleColor:nil];
    [leftButton setImageNormal:[UIImage imageNamed:@"ic_back"]];
    [leftButton addTarget:self action:@selector(backViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    
    [self setSaveUI];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(saveUserInfo)];
    self.navigationItem.rightBarButtonItem = rightItem;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)dealloc
{
    //注销掉所有代理和关闭数据库
    
}

//- (void)setInitUI
//{
//    self.headImageView.backgroundColor = CLEAR_COLOR;
//}

- (void)setSaveUI
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_SETTING]) {
        NSLog(@"hello == %@",[[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_SETTING]);
        [self.userNameTextField setText:[[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_SETTING]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:USER_HEADIMAGE_SETTING]) {
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:USER_HEADIMAGE_SETTING];
        [self.headImageView setImage:[UIImage imageWithData:imageData]];
    }else {
        self.headImageView.backgroundColor = [UIColor whiteColor];
    }
}

//判断是否是公制单位
- (BOOL)isMetricOrImperialSystem
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:LONG_MEASURE]) {
        BOOL isMetric = [[NSUserDefaults standardUserDefaults] boolForKey:LONG_MEASURE];
        return isMetric;
    }else {
        return NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action
- (void)backViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setHeadImage
{
    AlertTool *alert = [AlertTool alertWithTitle:nil message:nil style:UIAlertControllerStyleActionSheet];
    [alert addAction:[AlertAction actionWithTitle:NSLocalizedString(@"photoLibrry", nil) style:AlertToolStyleDefault handler:^(AlertAction *action) {
        UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
        PickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//方式1
        //允许编辑，即放大裁剪
        PickerImage.allowsEditing = YES;
        //自代理
        PickerImage.delegate = self;
        //页面跳转
        [self presentViewController:PickerImage animated:YES completion:nil];
    }]];
    //按钮：拍照，类型：UIAlertActionStyleDefault
    [alert addAction:[AlertAction actionWithTitle:NSLocalizedString(@"takePhoto", nil) style:AlertToolStyleDefault handler:^(AlertAction *action) {
        UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
        PickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;//方式1
        //允许编辑，即放大裁剪
        PickerImage.allowsEditing = YES;
        //自代理
        PickerImage.delegate = self;
        //页面跳转
        [self presentViewController:PickerImage animated:YES completion:nil];
    }]];
    //按钮：取消，类型：UIAlertActionStyleCancel
    [alert addAction:[AlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:AlertToolStyleCancel handler:nil]];
    [alert show];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

//PickerImage完成后的代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //定义一个newPhoto，用来存放我们选择的图片。
    UIImage *newPhoto = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    //把newPhono设置成头像
    [self.headImageView setImage:newPhoto];
    //关闭当前界面，即回到主界面去
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showInfoPickerView:(NSString *)infoText
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n\n\n\n\n" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self.currentIndex = -1;
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        switch (self.pickerType) {
            case PickerTypeGender:
                self.infoModel.gender = self.currentIndex;
                break;
            case PickerTypeAge:
                self.infoModel.age = self.ageArr[self.currentIndex];
                break;
            case PickerTypeHeight:
            {
                if (self.isMetric) {
                    self.infoModel.height = self.heightArr[self.currentIndex];
                }else {
                    //如果为英制，公制转换成英制在显示
                    float height = [UnitsTool cmAndInch:((NSString *)self.heightArr[self.currentIndex]).integerValue withMode:ImperialToMetric];
                    self.infoModel.height = [NSString stringWithFormat:@"%.0f", height];
                }
            }
                break;
            case PickerTypeWeight:
            {
                if (self.isMetric) {
                    self.infoModel.weight = self.weightArr[self.currentIndex];
                }else {
                    float weight = [UnitsTool kgAndLb:((NSString *)self.weightArr[self.currentIndex]).integerValue withMode:ImperialToMetric];
                    self.infoModel.weight = [NSString stringWithFormat:@"%.0f", weight];
                }
            }
                break;
                
            default:
                break;
        }
        self.dataArr = nil;
        [self.infoTableView reloadData];
    }];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    
    self.infoPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, alert.view.frame.size.width - 30, 216)];
    self.infoPickerView.dataSource = self;
    self.infoPickerView.delegate = self;
    switch (self.pickerType) {
        case PickerTypeGender:
        {
            NSInteger index;
            if (![infoText isEqualToString:NSLocalizedString(@"plsChoose", nil)]) {
                index = self.infoModel.gender;
            }else {
                index = 0;
            }
            [self.infoPickerView selectRow:index inComponent:0 animated:NO];
            [alert.view addSubview:self.infoPickerView];
        }
            break;
        case PickerTypeAge:
        {
            NSInteger index;
            if (![infoText isEqualToString:NSLocalizedString(@"plsChoose", nil)]) {
                NSUInteger ind = [self.ageArr indexOfObject:self.infoModel.age];
                if(ind == NSNotFound) {
                    index = 0;
                }else {
                    index = ind;
                }
            }else {
                index = 0;
            }
            [self.infoPickerView selectRow:index inComponent:0 animated:NO];
            [alert.view addSubview:self.infoPickerView];
        }
            break;
        case PickerTypeHeight:
        {
            NSInteger index;
            if (![infoText isEqualToString:NSLocalizedString(@"plsChoose", nil)]) {
                NSUInteger ind = 0;
                if (self.isMetric) {
                    ind = [self.heightArr indexOfObject:self.infoModel.height];
                }else {
                    float height = [UnitsTool cmAndInch:((NSString *)self.infoModel.height).integerValue withMode:MetricToImperial];
                    ind = [self.heightArr indexOfObject:[NSString stringWithFormat:@"%.0f", height]];
                }
                if(ind == NSNotFound) {
                    index = 0;
                }else {
                    index = ind;
                }
            }else {
                index = 0;
            }
            [self.infoPickerView selectRow:index inComponent:0 animated:NO];
            [alert.view addSubview:self.infoPickerView];
        }
            break;
        case PickerTypeWeight:
        {
            NSInteger index;
            if (![infoText isEqualToString:NSLocalizedString(@"plsChoose", nil)]) {
                NSUInteger ind = 0;
                if (self.isMetric) {
                    ind = [self.weightArr indexOfObject:self.infoModel.weight];
                }else {
                    float weight = [UnitsTool kgAndLb:((NSString *)self.infoModel.weight).integerValue withMode:MetricToImperial];
                    ind = [self.weightArr indexOfObject:[NSString stringWithFormat:@"%.0f", weight]];
                }
                if(ind == NSNotFound) {
                    index = 0;
                }else {
                    index = ind;
                }
            }else {
                index = 0;
            }
            [self.infoPickerView selectRow:index inComponent:0 animated:NO];
            [alert.view addSubview:self.infoPickerView];
        }
            break;
            
        default:
            break;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -ButtonAction
- (void)saveUserInfo
{
    [self.view endEditing:YES];
    if ([BleManager shareInstance].connectState == kBLEstateDisConnected) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showTheStateBar];
    }else {
        //写入身高体重到设备
        [[BleManager shareInstance] writeUserInfoToPeripheralWeight: self.infoModel.weight andHeight:self.infoModel.height];
    }
}

- (void)setUserInfoWhetherSuccess:(NSNotification *)noti
{
    BOOL isFirst = noti.userInfo[@"success"];//success 里保存这设置是否成功
    NSLog(@"isFirst:%d",isFirst);
    //这里不能直接写 if (isFirst),必须如下写法
    if (isFirst == 1) {
        MDToast *toast = [[MDToast alloc] initWithText:NSLocalizedString(@"saveSuccess", nil) duration:1.5];
        [toast show];
        
        //写入本地
        //保存用户名
        [[NSUserDefaults standardUserDefaults] setObject:self.userNameTextField.text forKey:USER_NAME_SETTING];
        //保存用户头像
        NSData *imageData = UIImagePNGRepresentation(self.headImageView.image);
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:USER_HEADIMAGE_SETTING];
        //保存用户的其他基本信息
        self.infoModel.userName = self.userNameTextField.text;
        NSData *infoData = [NSKeyedArchiver archivedDataWithRootObject:self.infoModel];
        [[NSUserDefaults standardUserDefaults] setObject:infoData forKey:USER_INFO_SETTING];
    }else {
        MDToast *toast = [[MDToast alloc] initWithText:NSLocalizedString(@"saveFail", nil) duration:1.5];
        [toast show];
    }
}

#pragma mark - UIPickerViewDelegate && UIPickerViewDataSource
// UIPickerViewDataSource中定义的方法，该方法的返回值决定改控件包含多少列
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// UIPickerViewDataSource中定义的方法，该方法的返回值决定该控件指定列包含多少哥列表项

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (self.pickerType) {
        case PickerTypeGender:
            return self.genderArr.count;
            break;
        case PickerTypeAge:
            return self.ageArr.count;
            break;
        case PickerTypeHeight:
            return self.heightArr.count;
            break;
        case PickerTypeWeight:
            return self.weightArr.count;
            break;
            
        default:
            break;
    }
    
    return 0;
}

// UIPickerViewDelegate中定义的方法，该方法返回NSString将作为UIPickerView中指定列和列表项上显示的标题

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (self.pickerType) {
        case PickerTypeGender:
            return self.genderArr[row];
            break;
        case PickerTypeAge:
            return self.ageArr[row];
            break;
        case PickerTypeWeight:
            return self.weightArr[row];
            break;
        case PickerTypeHeight:
            return self.heightArr[row];
            break;
            
        default:
            break;
    }
    return 0;
}

// 当用户选中UIPickerViewDataSource中指定列和列表项时激发该方法
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component

{
    switch (self.pickerType) {
        case PickerTypeGender:
            self.currentIndex = row;
            break;
            
        case PickerTypeAge:
            self.currentIndex = row;
            break;
            
        case PickerTypeHeight:
            self.currentIndex = row;
            break;
            
        case PickerTypeWeight:
            self.currentIndex = row;
            break;
            
        default:
            break;
    }
}

#pragma mark - UITableViewDelegate && UITableViewDataSource

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
    UserInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UserInfoTableViewCellID];
    
    cell.model = self.dataArr[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.pickerType = indexPath.row;
    UserInfoSettingModel *model = self.dataArr[indexPath.row];
    [self showInfoPickerView:model.placeHoldText];
}

#pragma mark - BleReceiveDelegate
- (void)receiveUserInfoWithModel:(manridyModel *)manridyModel
{
    if (manridyModel.receiveDataType == ReturnModelTypeUserInfoModel) {
        if (manridyModel.isReciveDataRight == ResponsEcorrectnessDataRgith) {
            
        }
    }
}

#pragma mark - 懒加载
- (UIImageView *)headImageView
{
    if (!_headImageView) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = CLEAR_COLOR;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:USER_HEADIMAGE_SETTING]) {
            NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:USER_HEADIMAGE_SETTING];
            [imageView setImage:[UIImage imageWithData:imageData]];
        }else {
            [imageView setImage:[UIImage imageNamed:@"set_head"]];
        }
        imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setHeadImage)];
        [imageView addGestureRecognizer:tap];
        
        [self.view addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view.mas_centerX);
            make.top.equalTo(self.view.mas_top).offset(80);
            make.width.equalTo(@127);
            make.height.equalTo(@127);
        }];
        imageView.layer.masksToBounds = YES;
        imageView.layer.borderWidth = 1;
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        imageView.layer.cornerRadius = 127 / 2;
        
        _headImageView = imageView;
    }
    
    return _headImageView;
}

- (UITextField *)userNameTextField
{
    if (!_userNameTextField) {
        UITextField *textField = [[UITextField alloc] init];
        textField.placeholder = [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_SETTING] ? [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_SETTING] : @"用户名";
        
//        [textField setValue:WHITE_COLOR forKeyPath:@"_placeholderLabel.textColor"];
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.textAlignment = NSTextAlignmentCenter;
        textField.font = [UIFont systemFontOfSize:14];
        
        [self.view addSubview:textField];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view.mas_centerX);
            make.top.equalTo(self.view.mas_top).offset(215);
            make.width.equalTo(@200);
            make.height.equalTo(@34);
        }];
        _userNameTextField = textField;
    }
    
    return _userNameTextField;
}

- (UITableView *)infoTableView
{
    if (!_infoTableView) {
        UITableView *_tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.scrollEnabled = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
        _tableView.backgroundColor = CLEAR_COLOR;
        
        [_tableView registerClass:NSClassFromString(UserInfoTableViewCellID)forCellReuseIdentifier:UserInfoTableViewCellID];
        
        [self.view addSubview:_tableView];
        _infoTableView = _tableView;
    }
    
    return _infoTableView;
}

- (NSArray *)dataArr
{
    if (!_dataArr) {
        NSArray *nameArr = @[NSLocalizedString(@"gender", nil),NSLocalizedString(@"age", nil),NSLocalizedString(@"height", nil),NSLocalizedString(@"weight", nil)];
        NSArray *fieldPlaceholdeArr;
        if (self.infoModel) {
            //如果当前是公制，直接显示公制
            if (self.isMetric) {
                fieldPlaceholdeArr = @[self.infoModel.gender ? NSLocalizedString(@"female", nil) : NSLocalizedString(@"male", nil),
                                       self.infoModel.age ? self.infoModel.age : NSLocalizedString(@"plsChoose", nil),
                                       self.infoModel.height ? self.infoModel.height : NSLocalizedString(@"plsChoose", nil),
                                       self.infoModel.weight ? self.infoModel.weight : NSLocalizedString(@"plsChoose", nil)];
            }else {
                //如果为英制，公制转换成英制在显示
                float height = [UnitsTool cmAndInch:self.infoModel.height.integerValue withMode:MetricToImperial];
                float weight = [UnitsTool kgAndLb:self.infoModel.weight.integerValue withMode:MetricToImperial];
                fieldPlaceholdeArr = @[self.infoModel.gender ? NSLocalizedString(@"female", nil) : NSLocalizedString(@"male", nil),
                                       self.infoModel.age ? self.infoModel.age : NSLocalizedString(@"plsChoose", nil),
                                       self.infoModel.height ? [NSString stringWithFormat:@"%.0f", height] : NSLocalizedString(@"plsChoose", nil),
                                       self.infoModel.weight ? [NSString stringWithFormat:@"%.0f", weight] : NSLocalizedString(@"plsChoose", nil)];
            }
        }else {
            fieldPlaceholdeArr = @[NSLocalizedString(@"plsChoose", nil),NSLocalizedString(@"plsChoose", nil),NSLocalizedString(@"plsChoose", nil),NSLocalizedString(@"plsChoose", nil)];
        }
        
        NSArray *unitArr = @[@"",NSLocalizedString(@"old", nil),self.isMetric ? @"(cm)" : @"(In)",self.isMetric ? @"(kg)" : @"(lb)"];
        NSMutableArray *mutArr = [NSMutableArray array];
        for (int index = 0; index < nameArr.count; index ++) {
            UserInfoSettingModel *model = [[UserInfoSettingModel alloc] init];
            model.nameText = nameArr[index];
            model.placeHoldText = fieldPlaceholdeArr[index];
            model.unitText = unitArr[index];
            model.isGenderCell = index == 0 ? YES : NO;
            [mutArr addObject:model];
        }
        
        _dataArr = [NSArray arrayWithArray:mutArr];
    }
    
    return _dataArr;
}

- (UserInfoModel *)infoModel
{
    if (!_infoModel) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:USER_INFO_SETTING]) {
            NSData *infoData = [[NSUserDefaults standardUserDefaults] objectForKey:USER_INFO_SETTING];
            _infoModel = [NSKeyedUnarchiver unarchiveObjectWithData:infoData];
        }else {
            _infoModel = [[UserInfoModel alloc] init];
        }
    }
    return _infoModel;
}

- (NSArray *)genderArr
{
    if (!_genderArr) {
        _genderArr = @[NSLocalizedString(@"male", nil),NSLocalizedString(@"female", nil)];
    }
    return _genderArr;
}

- (NSArray *)ageArr
{
    if (!_ageArr) {
        NSMutableArray *ageMutArr = [NSMutableArray array];
        for (int i = 0; i <= 100; i ++) {
            NSString *age = [NSString stringWithFormat:@"%d",i];
            [ageMutArr addObject:age];
        }
        _ageArr = ageMutArr;
    }
    return _ageArr;
}

- (NSArray *)heightArr
{
    if (!_heightArr) {
        NSMutableArray *heightMutArr = [NSMutableArray array];
        if (self.isMetric) {
            for (int i = 90; i <= 200; i ++) {
                NSString *height = [NSString stringWithFormat:@"%d",i];
                [heightMutArr addObject:height];
            }
        }else {
            for (int i = 35; i <= 78; i ++) {
                NSString *height = [NSString stringWithFormat:@"%d",i];
                [heightMutArr addObject:height];
            }
        }
        
        _heightArr = heightMutArr;
    }
    
    return _heightArr;
}

- (NSArray *)weightArr
{
    if (!_weightArr) {
        NSMutableArray *weightMutArr = [NSMutableArray array];
        if (self.isMetric) {
            //公制数据源
            for (int i = 15; i <= 150; i ++) {
                NSString *weight = [NSString stringWithFormat:@"%d",i];
                [weightMutArr addObject:weight];
            }
        }else {
            //英制数据源
            for (int i = 33; i <= 330; i ++) {
                NSString *weight = [NSString stringWithFormat:@"%d",i];
                [weightMutArr addObject:weight];
            }
        }
        
        _weightArr = weightMutArr;
    }
    
    return _weightArr;
}

@end
