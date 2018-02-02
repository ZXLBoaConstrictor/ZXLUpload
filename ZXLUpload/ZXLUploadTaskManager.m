//
//  ZXLUploadTaskManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadTaskManager.h"

@interface ZXLUploadTaskManager ()
@property (nonatomic,strong)NSMutableDictionary * uploadTasks;
@end

@implementation ZXLUploadTaskManager

#pragma 懒加载
-(NSMutableDictionary * )uploadTasks{
    if (!_uploadTasks) {
        _uploadTasks = [NSMutableDictionary dictionary];
    }
    return _uploadTasks;
}

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadTaskManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadTaskManager alloc] init];
    });
    return _sharedObject;
}

- (instancetype)init{
    if (self = [super init]) {
        [self localTaskInfo];
    }
    return self;
}

-(void)localTaskInfo{
    //读取本地上传结果文件信息
    NSMutableDictionary * tmpUploadTaskInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadTaskInfo];
    if (ISDictionaryValid(tmpUploadTaskInfo)) {
        for (NSString *dictKey in [tmpUploadTaskInfo allKeys]) {
            [self.uploadTasks setValue:[ZXLTaskInfoModel dictionary:[tmpUploadTaskInfo valueForKey:dictKey]] forKey:dictKey];
        }
    }
}

-(ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return nil;
    
    return [self.uploadTasks valueForKey:identifier];
}




-(void)changeFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result{
    
}

-(BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier{
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
