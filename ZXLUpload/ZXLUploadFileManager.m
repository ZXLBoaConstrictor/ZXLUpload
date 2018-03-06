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
#import "ZXLNetworkManager.h"
//#import "baseAliOSSManage.h"

@implementation ZXLUploadFileManager

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadFileManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadFileManager alloc] init];
        
    });
    return _sharedObject;
}

- (instancetype)init{
    if (self = [super init]) {

    }
    return self;
}

-(void)taskUploadFile:(ZXLFileInfoModel *)fileInfo
             progress:(void (^)(float percent))progress
               result:(void (^)(ZXLFileUploadType nResult,NSString *resultURL))result
{
    fileInfo.progressType = ZXLFileUploadProgressUpload;
    [[ZXLUploadFileResultCenter shareUploadResultCenter] saveUploadProgress:fileInfo];
    
    //上传后的文件key (即文件名称)
    NSString * uploadKey = [fileInfo uploadKey];
    //文件在本地地址
    NSString *localUploadURL = [fileInfo localUploadURL];
    
//    //文件上传实现
//    OSSRequest *request = [[baseAliOSSManage shareOssManage] uploadFile:uploadKey localFilePath:localUploadURL progress:^(float percent) {
//        if (percent < 1) {
//            fileInfo.progress = percent;
//            [[ZXLUploadFileResultCenter shareUploadResultCenter] saveUploadProgress:fileInfo];
//        }
//    } result:^(OSSTask *task) {
//        
//        OSSInitMultipartUploadResult * uploadResult = task.result;
//        if (task && uploadResult && uploadResult.httpResponseCode == 200) {
//            //上传结束 成功
//            [fileInfo setUploadResultSuccess];
//            progress(1.0);
//            result(ZXLFileUploadSuccess,[ZXLFileUtils serverAddressFileURL:uploadKey]);
//        }else
//        {
//            //上传结束 失败
//            [fileInfo setUploadResultError:ZXLFileUploadError];
//            progress(1.0);
//            result(ZXLFileUploadError,@"");
//        }
//    }];
//    
//    if (request) {
//        [[ZXLUploadFileResultCenter shareUploadResultCenter] addUploadRequest:request with:fileInfo.identifier];
//    }

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
                if (!bResult) {
                   compressError = YES;
                }
                
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
