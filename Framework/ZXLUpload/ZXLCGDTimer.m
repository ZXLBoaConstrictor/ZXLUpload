//
//  ZXLCGDTimer.m
//  testTimer
//
//  Created by 张小龙 on 2018/7/18.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLCGDTimer.h"
@interface ZXLCGDTimer()
@property (nonatomic, copy) NSString  * timerKey;
@property (nonatomic, strong) NSMutableDictionary * timerContainer;
@end

@implementation ZXLCGDTimer

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    static ZXLCGDTimer * manager = nil;
    dispatch_once(&pred, ^{
        manager = [[ZXLCGDTimer alloc] init];
    });
    return manager;
}

-(void)dealloc{
    [self cancel];
}

-(instancetype)initWithTimeInterval:(NSInteger)interval target:(id)target selector:(SEL)selector parameter:(id)parameter{
    if (interval == 0 || !target || !selector) {
        return nil;
    }
    
    if (self = [super init]) {
        self.timerKey = [self addTimerWithTimeInterval:interval target:target selector:selector userInfo:parameter repeats:YES fire:NO];
    }
    return self;
}

-(NSMutableDictionary *)timerContainer{
    if (!_timerContainer) {
        _timerContainer = [NSMutableDictionary dictionary];
    }
    return _timerContainer;
}

-(NSString *)addTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               target:(id)target
                             selector:(SEL)selector
                             userInfo:(id)userInfo
                              repeats:(BOOL)repeats
                                 fire:(BOOL)fire{
    
    __block  NSString *timerKey = [NSString stringWithFormat:@"%p%@%f%f",target,NSStringFromSelector(selector),timeInterval,[[NSDate date] timeIntervalSinceNow]];
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    [self.timerContainer setObject:timer forKey:timerKey];
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(timeInterval * NSEC_PER_SEC);
    dispatch_source_set_timer(timer, start, interval, 0);
    typeof(self) __weak weakSelf = self;
    __weak id weakTarget = target;
    dispatch_source_set_event_handler(timer, ^{
        if (weakTarget && selector && [weakTarget respondsToSelector:selector]) {
            IMP imp = [weakTarget methodForSelector:selector];
            void (*func)(id, SEL,id) = (void *)imp;
            func(weakTarget, selector,userInfo);
            if (!repeats) {
                dispatch_cancel(timer);
                [weakSelf.timerContainer removeObjectForKey:timerKey];
            }
        }else{
            dispatch_cancel(timer);
            [weakSelf.timerContainer removeObjectForKey:timerKey];
        }
    });
    
    if (fire) {
        dispatch_resume(timer);
    }
    return timerKey;
}

//启动
- (void)start{
    [self resume];
}
//暂停
- (void)pause{
    dispatch_source_t timer = (dispatch_source_t)[self.timerContainer objectForKey:self.timerKey];
    if (timer) {
        dispatch_suspend(timer);
    }
}

//继续
- (void)resume{
    dispatch_source_t timer = (dispatch_source_t)[self.timerContainer objectForKey:self.timerKey];
    if (timer) {
        dispatch_resume(timer);
    }
}

//销毁
- (void)cancel{
    dispatch_source_t timer = (dispatch_source_t)[self.timerContainer objectForKey:self.timerKey];
    if (timer) {
        dispatch_cancel(timer);
        [self.timerContainer removeObjectForKey:self.timerKey];
    }
}


+(void)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               target:(id)target
                             selector:(SEL)selector
                             userInfo:(id)userInfo
                              repeats:(BOOL)repeats{
    [[ZXLCGDTimer manager] addTimerWithTimeInterval:timeInterval
                                             target:target
                                           selector:selector
                                           userInfo:userInfo
                                            repeats:repeats
                                               fire:YES];
}


@end
