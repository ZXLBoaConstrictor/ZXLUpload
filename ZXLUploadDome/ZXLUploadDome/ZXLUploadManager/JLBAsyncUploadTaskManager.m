//
//  JLBAsyncUploadTaskManager.m
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "JLBAsyncUploadTaskManager.h"
#import "JLBUploadTaskModel.h"
#import "ZXLTaskFmdb.h"

@interface JLBAsyncUploadTaskManager()
@property(nonatomic,strong)ZXLSyncMutableDictionary *uploadTasks;
@end

@implementation JLBAsyncUploadTaskManager
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static JLBAsyncUploadTaskManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[JLBAsyncUploadTaskManager alloc] initLoadLocalUploadInfo];
    });
    return _sharedObject;
}

- (instancetype)initLoadLocalUploadInfo{
    if (self = [super init]) {
        //读取本地上传信息
        NSMutableArray<JLBUploadTaskModel *> * tasks = [[ZXLTaskFmdb manager] selectAllUploadTaskInfo];
        for (JLBUploadTaskModel * model in tasks) {
            [self.uploadTasks setObject:model forKey:model.taskTid];
        }
    }
    return self;
}

-(ZXLSyncMutableDictionary *)uploadTasks{
    if (!_uploadTasks) {
        _uploadTasks = [[ZXLSyncMutableDictionary alloc] init];
    }
    return _uploadTasks;
}

-(BOOL)clearCache{
    if (![[ZXLUploadFileResultCenter shareUploadResultCenter] clearAllUploadFileInfo]
        ||![[ZXLUploadTaskManager manager] clearUploadTask]) {
        return NO;
    }

    [self.uploadTasks removeAllObjects];
    [[ZXLTaskFmdb manager] clearUploadTaskInfo];
    return YES;
}

-(void)restUploadTaskReStartProcess{
    [[ZXLUploadTaskManager manager] restUploadTaskReStartProcess];
}

-(void)addUploadTask:(JLBUploadTaskModel *)taskModel{
    if (!taskModel || [self.uploadTasks objectForKey:taskModel.taskTid]) return;
    
    [self.uploadTasks setObject:taskModel forKey:taskModel.taskTid];
    [[ZXLTaskFmdb manager] insertUploadTaskInfo:taskModel];
}

-(void)reomveUploadTask:(NSString *)taskId{
    if (!ZXLISNSStringValid(taskId)) return;
    
    JLBUploadTaskModel *taskModel = [self.uploadTasks objectForKey:taskId];
    if (taskModel) {
        [[ZXLUploadTaskManager manager] removeTaskForIdentifier:taskModel.uploadIdentifier];
    }
    
    [self.uploadTasks removeObjectForKey:taskId];
    [[ZXLTaskFmdb manager] deleteUploadTaskInfo:taskModel];
}

-(NSMutableArray<JLBUploadTaskModel *> *)allUploadTask{
    NSMutableArray<JLBUploadTaskModel *> * ayTasks = [NSMutableArray array];
    NSArray *allKeys = [self.uploadTasks allKeys];
    for (NSString *taskKey in allKeys) {
        [ayTasks addObject:[self.uploadTasks objectForKey:taskKey]];
    }
    return ayTasks;
}

-(NSInteger)taskCount{
    return [self.uploadTasks count];
}

-(JLBUploadTaskModel *)getTaskInfoForUploadIdentifier:(NSString *)uploadIdentifier{
    if (!ZXLISNSStringValid(uploadIdentifier)) return nil;
    
    JLBUploadTaskModel *tempTaskModel = nil;
    NSMutableArray<JLBUploadTaskModel *> * ayTasks = [self allUploadTask];
    for (JLBUploadTaskModel *taskModel in ayTasks) {
        if ([taskModel.uploadIdentifier isEqualToString:uploadIdentifier]) {
            tempTaskModel = taskModel;
            break;
        }
    }
    return tempTaskModel;
}

-(ZXLTaskInfoModel *)getUploadTaskInfoForTaskId:(NSString *)taskId{
    if (!ZXLISNSStringValid(taskId)) return nil;
    
    JLBUploadTaskModel *taskModel = [self.uploadTasks objectForKey:taskId];
    if (taskModel && ZXLISNSStringValid(taskModel.uploadIdentifier)) {
        return [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:taskModel.uploadIdentifier];
    }
    return nil;
}

+(ZXLFileInfoModel *)getUploadFileInfoForUploadIdentifier:(NSString *)uploadIdentifier
                                           fileIdentifier:(NSString *)fileIdentifier{
    ZXLTaskInfoModel *taskInfo = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:uploadIdentifier];
    if (taskInfo) {
        return [taskInfo uploadFileForIdentifier:fileIdentifier];
    }
    return nil;
}

+(void)removeFileInfoForUploadIdentifier:(NSString *)uploadIdentifier index:(NSInteger)index{
    ZXLTaskInfoModel *taskInfo = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:uploadIdentifier];
    if (taskInfo) {
        [taskInfo removeUploadFileAtIndex:index];
    }
}

+(void)replaceJSTaskFileInfoForUploadIdentifier:(NSString *)uploadIdentifier index:(NSInteger)index{
    ZXLTaskInfoModel *taskInfo = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:uploadIdentifier];
    if (taskInfo) {
        NSInteger fileCount = [taskInfo uploadFilesCount];
        if (fileCount >= 2 && index < fileCount) {
            ZXLFileInfoModel * fileInfo = [taskInfo uploadFileAtIndex:fileCount - 1];
            [taskInfo replaceUploadFileAtIndex:index withUploadFile:fileInfo];
            [taskInfo removeUploadFileAtIndex:fileCount - 1];
        }
    }
}


+(void)startUploadForIdentifier:(NSString *)identifier complete:(ZXLUploadTaskResponseCallback)complete{
    [[ZXLUploadTaskManager manager] startUploadForIdentifier:identifier compress:^(float compressPercent) {
        if (compressPercent < 1) {
            [SVProgressHUD showProgress:compressPercent status:@"文件压缩中"];
        }
    } progress:^(float progressPercent) {
        if (progressPercent < 1) {
            [SVProgressHUD showProgress:progressPercent status:@"文件上传中"];
        }
    } complete:complete];
}

+(void)uploadFile:(ZXLFileInfoModel *)fileInfo complete:(ZXLUploadFileResponseCallback)complete{
    [[ZXLUploadFileManager manager] uploadFile:fileInfo progress:^(float progressPercent) {
        if (progressPercent < 1) {
            [SVProgressHUD showProgress:progressPercent status:@"文件上传中"];
        }
    } complete:complete];
}

+(void)uploadFile:(ZXLFileInfoModel *)fileInfo progress:(ZXLUploadFileProgressCallback)progress complete:(ZXLUploadFileResponseCallback)complete{
    [[ZXLUploadFileManager manager] uploadFile:fileInfo progress:progress complete:complete];
}


+(NSMutableArray *)creatUploadTaskFileShowInfoForUploadIdentifier:(NSString *)uploadIdentifier{
    NSMutableArray *array = [NSMutableArray array];
    ZXLTaskInfoModel *taskInfo = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:uploadIdentifier];
    if (taskInfo) {
        NSInteger fileCount = [taskInfo uploadFilesCount];
        if (fileCount > 0) {
            for (NSInteger i = 0 ;i< fileCount ;i++) {
                ZXLFileInfoModel * fileInfo = [taskInfo uploadFileAtIndex:i];
                if (fileInfo) {
                    id dataInfo = @(fileInfo.fileTime).stringValue;
                    if (fileInfo.fileType == ZXLFileTypeImage) {
                        dataInfo = [UIImage imageWithContentsOfFile:fileInfo.localURL];
                    }
                    
                    if (ZXLISNSStringValid(fileInfo.assetLocalIdentifier)) {
                        dataInfo = fileInfo.assetLocalIdentifier;
                    }
                    
                    //                    NSMutableDictionary*pDict = [baseUILoopScrollView creatDataInfo:fileInfo.fileType dateinfo:dataInfo dateURL:fileInfo.localURL fromAlbum:ISNSStringValid(fileInfo.assetLocalIdentifier)];
                    //                    if (NotEmpty(pDict)) {
                    //                        [array addObject:pDict];
                    //                    }
                }
            }
        }
    }
    return array;
}
+(void)showFilesForUploadIdentifier:(NSString *)uploadIdentifier index:(NSInteger)index{
    if (!ZXLISNSStringValid(uploadIdentifier)) return;
    
//    [JLBSystemDealMsg OnDealMes:JLBSystemActionPublicShowFile wParam:[baseUIShowFileViewController creatInfo:baseLoopScrollViewFile data:[JLBAsyncUploadTaskManager creatUploadTaskFileShowInfoForUploadIdentifier:uploadIdentifier] Index:index]];
}
@end
