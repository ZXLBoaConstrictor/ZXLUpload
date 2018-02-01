//
//  ZXLUploadTaskCenter.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadTaskCenter.h"
#import "ZXLTaskInfoModel.h"

@interface ZXLUploadTaskCenter ()
@property (nonatomic,strong)NSMutableArray<ZXLTaskInfoModel *> * uploadTasks;
@end

@implementation ZXLUploadTaskCenter

#pragma 懒加载
-(NSMutableArray<ZXLTaskInfoModel *> * )uploadTasks{
    if (!_uploadTasks) {
        _uploadTasks = [NSMutableArray array];
    }
    return _uploadTasks;
}

+(instancetype)shareUploadTask{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadTaskCenter * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadTaskCenter alloc] init];
    });
    return _sharedObject;
}


-(void)changeFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result{
    
}

-(BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier
{
    if (!ISNSStringValid(taskIdentifier) || !ISNSStringValid(fileIdentifier)) return NO;
    
    if (self.uploadTasks.count == 0) return YES;

    BOOL bExistence = NO;
    for (ZXLTaskInfoModel *taskInfo in self.uploadTasks) {
        if (!ISNSStringValid(taskIdentifier) || (ISNSStringValid(taskIdentifier) && ![taskIdentifier isEqualToString:taskInfo.identifier])) {
            ZXLUploadTaskType taskUploadResult = [taskInfo uploadTaskType];
            if ((taskUploadResult == ZXLUploadTaskTranscoding || taskUploadResult == ZXLUploadTaskLoading) && [taskInfo checkFileInTask:fileIdentifier]) {
                bExistence = YES;
                break;
            }
        }
    }
    return !bExistence;
}
@end
