//
//  SleepContentView.m
//  ManridyApp
//
//  Created by JustFei on 16/9/26.
//  Copyright © 2016年 Manridy.Bobo.com. All rights reserved.
//

#import "SleepContentView.h"
#import "SleepHisViewController.h"
#import "UnitsTool.h"
#import "BleManager.h"
#import "PNChart.h"
#import "FMDBManager.h"
#import "StepDataModel.h"
#import "BarView.h"
#import "XXBarChartView.h"
#import "TargetSettingModel.h"

#define BACK_WIDTH self.sleepChartBackView.bounds.size.width
#define BACK_HEIGHT self.sleepChartBackView.bounds.size.height

@interface SleepContentView () < PNChartDelegate >
{
    NSInteger sumStep;
    NSInteger sumMileage;
    NSInteger sumkCal;
    BOOL _isMetric;
    NSInteger _currentSleepData;
}

@property (nonatomic, strong) UIView *upView;
@property (nonatomic, strong) UILabel *stepLabel;
@property (nonatomic, strong) UILabel *mileageAndkCalLabel;
@property (nonatomic, strong) UILabel *InSleepLabel;
@property (nonatomic, strong) UILabel *outSleepLabel;
@property (nonatomic, strong) UILabel *awakeLabel;
@property (nonatomic, strong) PNCircleChart *sleepCircleChart;
@property (nonatomic, strong) XXBarChartView *sleepChartBackView;
@property (nonatomic, strong) UIView *view1;
@property (nonatomic, strong) BleManager *myBleManager;
@property (nonatomic, strong) NSMutableArray *dateArr;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) FMDBManager *myFmdbManager;
@property (nonatomic, strong) UILabel *leftTimeLabel;
@property (nonatomic, strong) UILabel *rightTimeLabel;
@property (nonatomic, strong) UILabel *noDataLabel;

@end

@implementation SleepContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCircleWhenTargetReset:) name:SET_MOTION_TARGET object:nil];
        
        _upView = [[UIView alloc] init];
        _upView.backgroundColor = SLEEP_CURRENT_BACKGROUND_COLOR;
        [self addSubview:_upView];
        [_upView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left);
            make.top.equalTo(self.mas_top);
            make.right.equalTo(self.mas_right);
            make.height.equalTo(self.mas_width);
        }];
        
        [self.sleepCircleChart mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_upView.mas_centerX);
            make.bottom.equalTo(_upView.mas_bottom).offset(-48 * VIEW_FRAME_WIDTH / 360);
            make.width.equalTo(@(220 * VIEW_FRAME_WIDTH / 360));
            make.height.equalTo(@(220 * VIEW_FRAME_WIDTH / 360));
        }];
        [self.sleepCircleChart strokeChart];
        [self.sleepCircleChart updateChartByCurrent:@(0)];
        
        [self.stepLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.sleepCircleChart.mas_centerX);
            make.centerY.equalTo(self.sleepCircleChart.mas_centerY);
        }];
        [self.stepLabel setText:@"--"];
        
        UILabel *todayLabel = [[UILabel alloc] init];
        [todayLabel setText:@"今日睡眠"];
        [todayLabel setTextColor:TEXT_WHITE_COLOR_LEVEL3];
        [todayLabel setFont:[UIFont systemFontOfSize:24]];
        [self addSubview:todayLabel];
        [todayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.sleepCircleChart.mas_centerX);
            make.bottom.equalTo(self.stepLabel.mas_top).offset(-18 * VIEW_FRAME_WIDTH / 360);
        }];
        
        UIImageView *headImageView = [[UIImageView alloc] init];
        [headImageView setImage:[UIImage imageNamed:@"sleep_sleep-icon"]];
        [self addSubview:headImageView];
        [headImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.sleepCircleChart.mas_centerX);
            make.bottom.equalTo(todayLabel.mas_top);
        }];
        
        UIView *lineView = [[UIView alloc] init];
        lineView.backgroundColor = WHITE_COLOR;
        [self addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.stepLabel.mas_bottom).offset(13 * VIEW_FRAME_WIDTH / 360);
            make.centerX.equalTo(self.sleepCircleChart.mas_centerX);
            make.width.equalTo(self.stepLabel.mas_width).offset(-6 * VIEW_FRAME_WIDTH / 360);
            make.height.equalTo(@1);
        }];
        
        [self.mileageAndkCalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.sleepCircleChart.mas_centerX);
            make.top.equalTo(lineView.mas_bottom).offset(2 * VIEW_FRAME_WIDTH / 360);
        }];
//        [self.mileageAndkCalLabel setText:@"23.7km/1800kcal"];
        
        MDButton *hisBtn = [[MDButton alloc] initWithFrame:CGRectZero type:MDButtonTypeFlat rippleColor:CLEAR_COLOR];
        [hisBtn setImage:[UIImage imageNamed:@"all_historyicon"] forState:UIControlStateNormal];
        hisBtn.backgroundColor = CLEAR_COLOR;
        [hisBtn addTarget:self action:@selector(showHisVC:) forControlEvents:UIControlEventTouchUpInside];
        [_upView addSubview:hisBtn];
        [hisBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_upView.mas_right).offset(-16);
            make.bottom.equalTo(_upView.mas_bottom).offset(-16);
            make.width.equalTo(@44);
            make.height.equalTo(@44);
        }];
        
        self.view1 = [[UIView alloc] init];
        self.view1.layer.borderWidth = 1;
        self.view1.layer.borderColor = TEXT_BLACK_COLOR_LEVEL0.CGColor;
        [self addSubview:self.view1];
        [self.view1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_upView.mas_bottom).offset(8);
            make.left.equalTo(self.mas_left).offset(-1);
            make.height.equalTo(@72);
            make.width.equalTo(@((VIEW_FRAME_WIDTH + 4) / 3));
        }];
        
        UILabel *view1Title = [[UILabel alloc] init];
        [view1Title setText:@"昨晚入睡"];
        [view1Title setTextColor:TEXT_BLACK_COLOR_LEVEL2];
        [view1Title setFont:[UIFont systemFontOfSize:12]];
        [self.view1 addSubview:view1Title];
        [view1Title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view1.mas_centerX);
            make.top.equalTo(@18);
        }];
        
        _InSleepLabel = [[UILabel alloc] init];
        [_InSleepLabel setText:@"--"];
        [_InSleepLabel setTextColor:TEXT_BLACK_COLOR_LEVEL4];
        [_InSleepLabel setFont:[UIFont systemFontOfSize:14]];
        [self.view1 addSubview:_InSleepLabel];
        [_InSleepLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view1.mas_centerX);
            make.bottom.equalTo(@-17);
        }];
        
        UIView *view2 = [[UIView alloc] init];
        view2.layer.borderWidth = 1;
        view2.layer.borderColor = TEXT_BLACK_COLOR_LEVEL0.CGColor;
        [self addSubview:view2];
        [view2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view1.mas_top);
            make.left.equalTo(self.view1.mas_right).offset(-1);
            make.height.equalTo(self.view1);
            make.width.equalTo(self.view1.mas_width);
        }];
        
        UILabel *view2Title = [[UILabel alloc] init];
        [view2Title setText:@"今天醒来"];
        [view2Title setTextColor:TEXT_BLACK_COLOR_LEVEL2];
        [view2Title setFont:[UIFont systemFontOfSize:12]];
        [view2 addSubview:view2Title];
        [view2Title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(view2.mas_centerX);
            make.top.equalTo(@18);
        }];
        
        _outSleepLabel = [[UILabel alloc] init];
        [_outSleepLabel setText:@"--"];
        [_outSleepLabel setTextColor:TEXT_BLACK_COLOR_LEVEL4];
        [_outSleepLabel setFont:[UIFont systemFontOfSize:14]];
        [view2 addSubview:_outSleepLabel];
        [_outSleepLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(view2.mas_centerX);
            make.bottom.equalTo(@-17);
        }];
        
        UIView *view3 = [[UIView alloc] init];
        view3.layer.borderWidth = 1;
        view3.layer.borderColor = TEXT_BLACK_COLOR_LEVEL0.CGColor;
        [self addSubview:view3];
        [view3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view1.mas_top);
            make.left.equalTo(view2.mas_right).offset(-1);
            make.height.equalTo(self.view1);
            make.width.equalTo(self.view1.mas_width);
        }];
        
        UILabel *view3Title = [[UILabel alloc] init];
        [view3Title setText:@"清醒时长"];
        [view3Title setTextColor:TEXT_BLACK_COLOR_LEVEL2];
        [view3Title setFont:[UIFont systemFontOfSize:12]];
        [view3 addSubview:view3Title];
        [view3Title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(view3.mas_centerX);
            make.top.equalTo(@18);
        }];
        
        _awakeLabel = [[UILabel alloc] init];
        [_awakeLabel setText:@"--"];
        [_awakeLabel setTextColor:TEXT_BLACK_COLOR_LEVEL4];
        [_awakeLabel setFont:[UIFont systemFontOfSize:14]];
        [view3 addSubview:_awakeLabel];
        [_awakeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(view3.mas_centerX);
            make.bottom.equalTo(@-17);
        }];

        UILabel *unitLabel3 = [[UILabel alloc] init];
        [unitLabel3 setTextColor:TEXT_BLACK_COLOR_LEVEL3];
        [unitLabel3 setFont:[UIFont systemFontOfSize:8]];
        [unitLabel3 setText:@"小时"];
        [self.view1 addSubview:unitLabel3];
        [unitLabel3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_awakeLabel.mas_right).offset(8);
            make.top.equalTo(_awakeLabel.mas_bottom);
        }];
        
        self.leftTimeLabel = [[UILabel alloc] init];
        [self.leftTimeLabel setText:@"00:00"];
        [self.leftTimeLabel setTextColor:TEXT_BLACK_COLOR_LEVEL2];
        [self.leftTimeLabel setFont:[UIFont systemFontOfSize:11]];
        [self addSubview:self.leftTimeLabel];
        [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).offset(16);
            make.bottom.equalTo(self.mas_bottom).offset(-12);
        }];
        
        self.rightTimeLabel = [[UILabel alloc] init];
        [self.self.rightTimeLabel setText:@"23:59"];
        [self.rightTimeLabel setTextColor:TEXT_BLACK_COLOR_LEVEL2];
        [self.rightTimeLabel setFont:[UIFont systemFontOfSize:11]];
        [self addSubview:self.rightTimeLabel];
        [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.mas_right).offset(-16);
            make.bottom.equalTo(self.leftTimeLabel.mas_bottom);
        }];
        
        self.sleepChartBackView.backgroundColor = TEXT_BLACK_COLOR_LEVEL0;
    }
    return self;
}

/** 更新视图 */
- (void)updateSleepUIWithDataArr:(NSArray *)dbArr
{
    /**
     1.更新当天睡眠的 UI
     */
    float sumData = 0.f;
    float lowData = 0.f;
    float deepData = 0.f;
    if (dbArr.count == 0) {
        self.noDataLabel.hidden = NO;
        [self.stepLabel setText:@"--"];
        [self.mileageAndkCalLabel setText:@""];
        [self.InSleepLabel setText:@"--"];
        [self.outSleepLabel setText:@"--"];
        [self.awakeLabel setText:@"--"];
        [self.sleepCircleChart updateChartByCurrent:@0];
        //没有数据
    }else {
        self.noDataLabel.hidden = YES;
        NSMutableArray *barDataArr = [NSMutableArray array];
        for (int index = 0; index < dbArr.count; index ++) {
            SleepModel *model = dbArr[index];
            sumData = sumData + model.sumSleep.floatValue;
            lowData = lowData + model.lowSleep.floatValue;
            deepData = deepData + model.deepSleep.floatValue;
            
            if (index == 0) {
                [self.InSleepLabel setText:[model.startTime substringFromIndex:11]];
                [self.leftTimeLabel setText:[model.startTime substringFromIndex:11]];
            }
            if (index == dbArr.count -1) {
                [self.outSleepLabel setText:[model.endTime substringFromIndex:11]];
                [self.rightTimeLabel setText:[model.endTime substringFromIndex:11]];
                _currentSleepData = 0;
            }
        }
        [self.stepLabel setText:[NSString stringWithFormat:@"%.1f", sumData / 60]];
        [self.mileageAndkCalLabel setText:[NSString stringWithFormat:@"深睡%.1f小时/浅睡%.1f小时", deepData / 60, lowData / 60]];
        [self.awakeLabel setText:@"--"];
        
        for (int index = 0; index < dbArr.count; index ++) {
            SleepModel *model = dbArr[index];
            
            XXBarDataModel *barModel = [[XXBarDataModel alloc] init];
            float xValue = (float)_currentSleepData / sumData * (BACK_WIDTH - 32);
            float xWidth = (float)model.sumSleep.integerValue / sumData * (BACK_WIDTH - 32);
            barModel.xValue = xValue;
            barModel.xWidth = xWidth;
            barModel.barType = model.deepSleep.integerValue != 0 ? BarTypeDeep : BarTypeLow;
            [barDataArr addObject:barModel];
            _currentSleepData = _currentSleepData + model.sumSleep.integerValue;
        }
        [self drawCircle:sumData / 60];
        //绘制睡眠图表
        [self.sleepChartBackView setXValues:barDataArr];
        [self.sleepChartBackView updateBar];
    }
}

- (void)updateCircleWhenTargetReset:(NSNotification *)noti
{
    BOOL isFirst = noti.userInfo[@"success"];//success 里保存这设置是否成功
    NSLog(@"isFirst:%d",isFirst);
    //这里不能直接写 if (isFirst),必须如下写法
    if (isFirst == 1) {
        //延迟一秒再去刷新圆环，因为保存目标到沙盒需要点时间
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self drawCircle:self.stepLabel.text.floatValue];
        });
    }
}

//更新圆环
- (void)drawCircle:(float)averageSleep
{
    float progress;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:TARGET_SETTING]) {
        NSArray *arr = [[NSUserDefaults standardUserDefaults] objectForKey:TARGET_SETTING];
        TargetSettingModel *sleepTargetModel = [NSKeyedUnarchiver unarchiveObjectWithData:arr.lastObject];
        progress = averageSleep / sleepTargetModel.target.floatValue;
    }else {
        progress = averageSleep / 8.f;
    }
    [self.sleepCircleChart updateChartByCurrent:@(progress)];
}

#pragma mark - PNChartDelegate



#pragma mark - Action
- (void)showHisVC:(MDButton *)sender
{
    SleepHisViewController *vc = [[SleepHisViewController alloc] init];
    [[self findViewController:self].navigationController pushViewController:vc animated:YES];
}

#pragma mark - 懒加载
- (PNCircleChart *)sleepCircleChart
{
    if (!_sleepCircleChart) {
        _sleepCircleChart = [[PNCircleChart alloc] initWithFrame:CGRectMake(0, 0, 220 * VIEW_FRAME_WIDTH / 360, 220 * VIEW_FRAME_WIDTH / 360) total:@1 current:@0 clockwise:YES shadow:YES shadowColor:SLEEP_CURRENT_SHADOW_CIRCLE_COLOR displayCountingLabel:NO overrideLineWidth:@10];
        [_sleepCircleChart setStrokeColor:SLEEP_CURRENT_CIRCLE_COLOR];
        
        [self addSubview:_sleepCircleChart];
    }
    
    return _sleepCircleChart;
}

- (XXBarChartView *)sleepChartBackView
{
    if (!_sleepChartBackView) {
        _sleepChartBackView = [[XXBarChartView alloc] init];
        
        [self addSubview:_sleepChartBackView];
        [_sleepChartBackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.bottom.equalTo(self.mas_bottom).offset(-34);
            make.top.equalTo(self.view1.mas_bottom).offset(10);
        }];
    }
    
    return _sleepChartBackView;
}

- (UILabel *)stepLabel
{
    if (!_stepLabel) {
        _stepLabel = [[UILabel alloc] init];
        [_stepLabel setTextColor:WHITE_COLOR];
        [_stepLabel setFont:[UIFont systemFontOfSize:50]];
        
        [self addSubview:_stepLabel];
    }
    
    return _stepLabel;
}

- (UILabel *)mileageAndkCalLabel
{
    if (!_mileageAndkCalLabel) {
        _mileageAndkCalLabel = [[UILabel alloc] init];
        [_mileageAndkCalLabel setTextColor:WHITE_COLOR];
        [_mileageAndkCalLabel setFont:[UIFont systemFontOfSize:14]];
        
        [self addSubview:_mileageAndkCalLabel];
    }
    
    return _mileageAndkCalLabel;
}

- (NSMutableArray *)dateArr
{
    if (!_dateArr) {
        _dateArr = [NSMutableArray array];
    }
    
    return _dateArr;
}

- (NSMutableArray *)dataArr
{
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    
    return _dataArr;
}

- (UILabel *)noDataLabel
{
    if (!_noDataLabel) {
        _noDataLabel = [[UILabel alloc] init];
        [_noDataLabel setText:@"无数据"];
        
        [self.sleepChartBackView addSubview:_noDataLabel];
        [_noDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.sleepChartBackView.mas_centerX);
            make.centerY.equalTo(self.sleepChartBackView.mas_centerY);
        }];
    }
    
    return _noDataLabel;
}

- (FMDBManager *)myFmdbManager
{
    if (!_myFmdbManager) {
        _myFmdbManager = [[FMDBManager alloc] initWithPath:DB_NAME];
    }
    
    return _myFmdbManager;
}



#pragma mark - 获取当前View的控制器的方法
- (UIViewController *)findViewController:(UIView *)sourceView
{
    id target=sourceView;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[UIViewController class]]) {
            break;
        }
    }
    return target;
}

@end
