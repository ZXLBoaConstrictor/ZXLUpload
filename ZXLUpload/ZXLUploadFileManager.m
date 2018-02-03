//
//  ZXLUploadFileManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadFileManager.h"
#import "ZXLFileUtils.h"
#import "ZXLUploadFileResultCenter.h"
#import "ZXLFileInfoModel.h"

@implementation ZXLUploadFileManager

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadFileManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadFileManager alloc] init];
    });
    return _sharedObject;
}

-(void)taskUploadFile:(ZXLFileInfoModel *)fileInfo
             progress:(void (^)(float percent))progress
               result:(void (^)(ZXLFileUploadType nResult,NSString *resultURL))result
{
    fileInfo.progressType = ZXLFileUploadProgressUpload;
    //上传后的文件key (即文件名称)
//    NSString * uploadKey = [fileInfo uploadKey];
    //文件在本地地址
//    NSString *localUploadURL = [fileInfo localUploadURL];
    
    //文件上传实现
    
}

- (void)uploadFile:(ZXLFileInfoModel *)fileInfo
          progress:(void (^)(float percent))progress
            result:(void (^)(ZXLFileUploadType nResult,NSString *resultURL))result
{
        //当有上传成功过的信息，不再继续进行压缩上传
    ZXLFileInfoModel * successFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadSuccessFileInfo:fileInfo.identifier];
    if (successFileInfo) {
        [fileInfo setUploadResultSuccess];
        progress(1.0);
        result(ZXLFileUploadSuccess,[ZXLFileUtils serverAddressFileURL:[fileInfo uploadKey]]);
        return;
    }

    __block BOOL compressError = NO;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (fileInfo.fileType == ZXLFileTypeVideo) {
            [fileInfo videoCompress:^(BOOL bResult) {
                compressError = bResult;
                dispatch_group_leave(group);
            }];
        }else
        {
            dispatch_group_leave(group);
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (compressError) {//文件压缩失败
            [fileInfo setUploadResultError:ZXLFileUploadError];
            progress(1.0);
            result(ZXLFileUploadError,@"");
        }else
        {
           [self taskUploadFile:fileInfo progress:progress result:result];
        }
    });
    
}

@end
