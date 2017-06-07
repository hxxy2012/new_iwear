//
//  BarChartView.m
//  SleepCharts
//
//  Created by Faith on 2017/4/14.
//  Copyright © 2017年 manridy. All rights reserved.
//

#import "XXBarChartView.h"

@interface XXBarChartView ()
{
    NSInteger _oldIndex;
}

@property (strong, nonatomic) NSMutableArray *subViewArr;
@property (strong, nonatomic) NSMutableArray *xPointArr;
@property (strong, nonatomic) BarView *selectView;
@property (assign, nonatomic) BOOL disSelectView;

@end

@implementation XXBarChartView

#pragma - init
- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setupDefaultValues];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupDefaultValues];
    }
    
    return self;
}

//设置默认值
- (void)setupDefaultValues
{
//    [super setupDefaultValues];
    self.backgroundColor = [UIColor whiteColor];
}

//设置X的值
- (void)setXValues:(NSArray *)xValues
{
    _xValues = xValues;
}

- (void)updateBar
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    if (_xValues.count == 0) {
        return;
    }
    
    _oldIndex = -2;
    //绘制睡眠图表
    for (int index = 0; index < _xValues.count; index ++) {
        //        SleepModel *model = xValues[index];
        
        XXBarDataModel *model = _xValues[index];
        DLog(@"%@", model);
        //1.创建视图，并计算宽度
        BarView *view = [[BarView alloc] initWithFrame:CGRectMake(model.xValue + 16, 0, model.xWidth, VIEW_FRAME_HEIGHT)];
        //2.着色
        view.backColor = model.barType == BarTypeDeep ? BackColorDeep : BackColorLow;
        view.isSelect = NO;
        [view setColor];
        view.tag = index;
        
        [self addSubview:view];
        [self.subViewArr addObject:view];
        [self.xPointArr addObject:[NSString stringWithFormat:@"%f", model.xValue + 16 + model.xWidth]];
        
    }
}

#pragma mark -图表点击事件
//- (NSInteger)indexOfTapPoint:(CGPoint)point
//{
//    if (point.x < 16 || point.x > VIEW_FRAME_WIDTH - 16) {
//        return -1;
//    }else {
//        for (int index = 0; index < self.xPointArr.count; index ++) {
//            if (point.x < ((NSString *)self.xPointArr[index]).floatValue) {
//                return index;
//            }
//        }
//    }
//    
//    return -1;
//}
//
//- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    self.disSelectView = NO;
//    UITouch *touch = [touches anyObject];
//    CGPoint point = [touch locationInView:self];
//    NSInteger index = [self indexOfTapPoint:point];
//    if (index != _oldIndex) {
//        if (index != -1) {
//            //改变选中的 view 的颜色为选中的颜色
//            self.selectView = self.subViewArr[index];
//            self.selectView.isSelect = YES;
//            [self.selectView setColor];
//            
//            /** 用 oldIndex 来记录之前点按的数据*/
//            if (_oldIndex != -2 && _oldIndex != -1) {
//                BarView *unSelectView = self.subViewArr[_oldIndex];
//                unSelectView.isSelect = NO;
//                [unSelectView setColor];
//            }
//            
//            _oldIndex = index;
//        }
//    }
//}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    //这里刷新后，后面的 view 就无法改变 backcolor 了，再尝试其他办法
////    [self updateBar];
//    [self touchPoint:touches withEvent:event];
//    [super touchesBegan:touches withEvent:event];
//}
//
//- (void)touchPoint:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    //Get the point user touched
//    UITouch *touch = [touches anyObject];
//    CGPoint touchPoint = [touch locationInView:self];
//    BarView *subview = (BarView *)[self hitTest:touchPoint withEvent:nil];
//    
//    DLog(@"clickBar == %ld", subview.tag);
//
//    subview.isSelect = YES;
//    [subview setColor];
//}

//- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    self.disSelectView = YES;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if (self.disSelectView) {
//            //改变选中的 view 的颜色为选中的颜色
//            self.selectView = self.subViewArr[_oldIndex];
//            self.selectView.isSelect = NO;
//            [self.selectView setColor];
//        }
//    });
//}

#pragma mark - lazy
- (NSMutableArray *)subViewArr
{
    if (!_subViewArr) {
        _subViewArr = [NSMutableArray array];
    }
    
    return _subViewArr;
}

- (NSMutableArray *)xPointArr
{
    if (!_xPointArr) {
        _xPointArr = [NSMutableArray array];
    }
    
    return _xPointArr;
}

@end
