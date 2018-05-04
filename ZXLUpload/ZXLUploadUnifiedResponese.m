//
//  ZXLUploadUnifiedResponese.m
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "ZXLUploadUnifiedResponese.h"
#import "ZXLUploadTaskManager.h"
@implementation ZXLUploadUnifiedResponese
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadUnifiedResponese * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadUnifiedResponese alloc] init];
    });
    return _sharedObject;
}

- (void)uploadTaskResponese:(ZXLTaskInfoModel *)taskInfo {
    SEL selResponese = NSSelectorFromString(@"extensionUnifiedResponese:");
    if ([self respondsToSelector:selResponese]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selResponese withObject:taskInfo];
#pragma clang diagnostic pop
    }
}
@end
