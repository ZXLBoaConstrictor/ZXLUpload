//
//  ZXLUploadFileManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadFileManager.h"
#import "ZXLUploadDefine.h"
#import "ZXLFileUtils.h"
#import "ZXLUploadFileResultCenter.h"
#import "ZXLFileInfoModel.h"
#import "ZXLNetworkManager.h"
#import "ZXLSyncMutableDictionary.h"
#import "ZXLSyncMapTable.h"
#import "ZXLDocumentUtils.h"
#import "ZXLTimer.h"
#import "ZXLPhotosUtils.h"
#import "ZXLUploadManager.h"
#import "ZXLUploadTaskManager.h"

@interface ZXLUploadFileManager ()
@property (nonatomic,strong)ZXLSyncMapTable * uploadFileResponseBlocks;
@property (nonatomic,strong)ZXLSyncMapTable * uploadFileProgressBlocks;
@property (nonatomic,strong)ZXLSyncMutableDictionary * waitResultFiles;
@property (nonatomic,strong)NSTimer * timer;//定时检查上传结果返回处理
@end

@implementation ZXLUploadFileManager
#pragma 懒加载
-(ZXLSyncMapTable * )uploadFileResponseBlocks{
    if (!_uploadFileResponseBlocks) {
        _uploadFileResponseBlocks = [ZXLSyncMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    }
    return _uploadFileResponseBlocks;
}

-(ZXLSyncMapTable * )uploadFileProgressBlocks{
    if (!_uploadFileProgressBlocks) {
        _uploadFileProgressBlocks = [ZXLSyncMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    }
    return _uploadFileProgressBlocks;
}

-(ZXLSyncMutableDictionary *)waitResultFiles{
    if (!_waitResultFiles) {
        _waitResultFiles = [[ZXLSyncMutableDictionary alloc] init];
    }
    return _waitResultFiles;
}

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNetWorkStatus) name:ZXLNetworkReachabilityNotification object:nil];
        [ZXLNetworkManager manager];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)refreshNetWorkStatus{
    //停止所有非上传任务文件上传(主要针对单个文件上传)
    if (![ZXLNetworkManager appHaveNetwork]) {
        [[ZXLUploadFileResultCenter shareUploadResultCenter] networkError];
    }
}

- (void)taskUploadFile:(ZXLFileInfoModel *)fileInfo
              progress:(ZXLUploadFileProgressCallback)progress
              complete:(ZXLUploadFileResponseCallback)complete{
    
    //当有上传成功过的信息，不再继续进行压缩上传
    ZXLFileInfoModel * successFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadSuccessFileInfo:fileInfo.identifier];
    if (successFileInfo) {
        [fileInfo setUploadStateWithTheSame:successFileInfo];
        if (progress) {
            progress(1.0);
        }
        if (complete) {
            complete(ZXLFileUploadSuccess,[ZXLFileUtils serverAddressFileURL:[fileInfo uploadKey]]);
        }
        return;
    }
    
    fileInfo.progressType = ZXLFileUploadProgressUpload;
    NSString * uploadKey = [fileInfo uploadKey];//上传后的文件key (即文件名称)
    NSString *localUploadURL = [fileInfo localUploadURL]; //文件在本地地址
    [[ZXLUploadFileResultCenter shareUploadResultCenter] saveUploadProgress:fileInfo];
    
    id request = [[ZXLUploadManager manager] uploadFile:uploadKey localFilePath:localUploadURL progress:^(float percent) {
        if (percent < 1) {
            if (progress) {
                progress(percent);
            }
            fileInfo.progress = percent;
            [[ZXLUploadFileResultCenter shareUploadResultCenter] saveUploadProgress:fileInfo];
        }
    } complete:^(BOOL result) {
        if (result) {
            //上传结束 成功
            [fileInfo setUploadResultSuccess];
            if (progress) {
                progress(1.0);
            }
            if (complete) {
                complete(ZXLFileUploadSuccess,[ZXLFileUtils serverAddressFileURL:uploadKey]);
            }
            
        }else{
            //上传结束 失败
            [fileInfo setUploadResultError:ZXLFileUploadError];
            if (progress) {
                progress(1.0);
            }
            if (complete) {
                complete(ZXLFileUploadError,@"");
            }
        }
    }];
    if (request) {
        [[ZXLUploadFileResultCenter shareUploadResultCenter] addUploadRequest:request with:fileInfo.identifier];
    }
}

- (void)uploadFile:(ZXLFileInfoModel *)fileInfo
          progress:(ZXLUploadFileProgressCallback)progress
          complete:(ZXLUploadFileResponseCallback)complete{
    
    //单文件上传的时候无网络直接返回上传出错，不做错误记录
    if (![ZXLNetworkManager appHaveNetwork]) {
        if (progress) {
            progress(1.0);
        }
        if (complete) {
            complete(ZXLFileUploadError,@"");
        }
        return;
    }
    
    //当有上传成功过的信息，不再继续进行压缩上传
    ZXLFileInfoModel * successFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadSuccessFileInfo:fileInfo.identifier];
    if (successFileInfo) {
        [fileInfo setUploadStateWithTheSame:successFileInfo];
        if (progress) {
            progress(1.0);
        }
        if (complete) {
            complete(ZXLFileUploadSuccess,[ZXLFileUtils serverAddressFileURL:[fileInfo uploadKey]]);
        }
        return;
    }
    
    //当有相同文件正在上传的时候等待上传结果
    ZXLFileInfoModel * progressFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadProgressFileInfo:fileInfo.identifier];
    if (progressFileInfo) {
        [fileInfo setUploadStateWithTheSame:progressFileInfo];
        [self.uploadFileProgressBlocks setObject:progress forKey:fileInfo.identifier];
        [self.uploadFileResponseBlocks setObject:complete forKey:fileInfo.identifier];
        [self.waitResultFiles setObject:fileInfo forKey:fileInfo.identifier];
        
        if ( !_timer) {
            _timer = [ZXLTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fileUploadProgress) userInfo:nil repeats:YES];
            [_timer fire];
        }
        return;
    }
    
    __block BOOL compressError = NO;
    dispatch_group_t group = dispatch_group_create();
    if (fileInfo.fileType == ZXLFileTypeVideo) {
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [fileInfo videoCompress:^(BOOL bResult) {
                if (!bResult) {
                    compressError = YES;
                }
                dispatch_group_leave(group);
            }];
        });
    }
    
    if (fileInfo.fileType == ZXLFileTypeImage
        && ZXLISNSStringValid(fileInfo.assetLocalIdentifier)
        && !ZXLISNSStringValid(fileInfo.localURL)) {
        
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [fileInfo albumImageRequest:^(BOOL bResult) {
                if (!bResult)
                    compressError = YES;
                dispatch_group_leave(group);
            }];
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (compressError) {//文件压缩失败
            [fileInfo setUploadResultError:ZXLFileUploadError];
            if (progress) {
                progress(1.0);
            }
            if (complete) {
                complete(ZXLFileUploadError,@"");
            }
        }else{
            [fileInfo resetFileInfo];
            [self taskUploadFile:fileInfo progress:progress complete:complete];
        }
    });
}

-(void)fileUploadProgress{
    NSMutableArray * ayFileKeys = [NSMutableArray arrayWithArray:[self.waitResultFiles allKeys]];
    for (NSString *identifier in ayFileKeys) {
        ZXLFileInfoModel * fileInfo = [self.waitResultFiles objectForKey:identifier];
        if (fileInfo) {
            //获得相同文件上传成功信息
            ZXLFileInfoModel * resultFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadSuccessFileInfo:fileInfo.identifier];
            if (!resultFileInfo) {
                //获得相同文件上传失败信息
                resultFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadErrorFileInfo:fileInfo.identifier];
            }
            if (!resultFileInfo) {
                //获得相同文件正在上传信息
                resultFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadProgressFileInfo:fileInfo.identifier];
            }
            
            if (resultFileInfo) {
                //文件上传进度
                ZXLUploadFileProgressCallback progressCallback = [self.uploadFileProgressBlocks objectForKey:fileInfo.identifier];
                if (progressCallback) {
                    progressCallback(resultFileInfo.progress);
                }
                
                //文件上传结果
                ZXLUploadFileResponseCallback responseCallback = [self.uploadFileResponseBlocks objectForKey:fileInfo.identifier];
                if (resultFileInfo.uploadResult == ZXLFileUploadSuccess) {
                    [fileInfo setUploadResultSuccess];
                    if (responseCallback) {
                        responseCallback(ZXLFileUploadSuccess,[ZXLFileUtils serverAddressFileURL:[fileInfo uploadKey]]);
                        [self.uploadFileResponseBlocks removeObjectForKey:fileInfo.identifier];
                        [self.uploadFileProgressBlocks removeObjectForKey:fileInfo.identifier];
                        [self.waitResultFiles removeObjectForKey:fileInfo.identifier];
                    }
                }else if (resultFileInfo.uploadResult == ZXLFileUploadError || resultFileInfo.uploadResult == ZXLFileUploadFileError){
                    if (responseCallback) {
                        responseCallback(ZXLFileUploadError,@"");
                        [self.uploadFileResponseBlocks removeObjectForKey:fileInfo.identifier];
                        [self.uploadFileProgressBlocks removeObjectForKey:fileInfo.identifier];
                        [self.waitResultFiles removeObjectForKey:fileInfo.identifier];
                    }
                }
            }
        }
    }
}
@end
