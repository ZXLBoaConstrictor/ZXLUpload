//
//  ZXLCGDTimer.h
//  testTimer
//
//  Created by 张小龙 on 2018/7/18.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZXLCGDTimer : NSObject
-(instancetype)initWithTimeInterval:(NSInteger)interval target:(id)target selector:(SEL)selector parameter:(id)parameter;


/**
 定时器GCD版
 
 @param timeInterval 时间 单位:秒
 @param target target
 @param selector 函数
 @param userInfo 参数
 @param repeats 是否重复
 */
+(void)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               target:(id)target
                             selector:(SEL)selector
                             userInfo:(id)userInfo
                              repeats:(BOOL)repeats;

//启动
- (void)start;
//暂停
- (void)pause;

//继续
- (void)resume;

//销毁
- (void)cancel;
@end
