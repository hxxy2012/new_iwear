//
//  BarChartView.h
//  SleepCharts
//
//  Created by Faith on 2017/4/14.
//  Copyright © 2017年 manridy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BarView.h"
#import "XXBarDataModel.h"

@interface XXBarChartView : UIView

@property (nonatomic, strong) NSArray *xValues;

- (void)updateBar;

@end