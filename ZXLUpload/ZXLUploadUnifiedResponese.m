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
    if ([self respondsToSelector:@selector(extensionUnifiedResponese:)]) {
        [self extensionUnifiedResponese:taskInfo];
    }
}

-(void)extensionUnifiedResponese:(ZXLTaskInfoModel *)taskInfo{
    if (taskInfo) {
        
    }
}
@end
