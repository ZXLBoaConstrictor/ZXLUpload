//
//  ZXLUploadTaskCenter.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadTaskCenter.h"

@implementation ZXLUploadTaskCenter

+(instancetype)shareUploadTask
{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadTaskCenter * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadTaskCenter alloc] init];
    });
    return _sharedObject;
}


-(void)changeFileUploadResult:(NSString *)uuid type:(ZXLFileUploadType)result
{
    
}
@end
