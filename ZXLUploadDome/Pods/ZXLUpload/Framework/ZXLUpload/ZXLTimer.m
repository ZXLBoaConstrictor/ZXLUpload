//
//  ZXLTimer.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/3/6.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLTimer.h"

@implementation ZXLTimer
+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                      target:(id)aTarget
                                    selector:(SEL)aSelector
                                    userInfo:(id)userInfo
                                     repeats:(BOOL)repeats{
    
    ZXLTimer * timer = [ZXLTimer new];
    timer.target = aTarget;
    timer.selector = aSelector;
    timer.timer = [NSTimer scheduledTimerWithTimeInterval:interval target:timer selector:@selector(fire:) userInfo:userInfo repeats:repeats];
    return timer.timer;
}



-(void)fire:(NSTimer *)timer{
    if (self.target && self.selector) {
        if ([self.target respondsToSelector:self.selector]) {
            IMP imp = [self.target methodForSelector:self.selector];
            void (*func)(id, SEL,id) = (void *)imp;
            func(self.target, self.selector,timer.userInfo);
        }
    } else {
        [self.timer invalidate];
    }
}
@end
