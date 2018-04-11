//
//  ZXLUploadTaskManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadTaskManager.h"
#import "ZXLSyncMutableDictionary.h"
#import "ZXLSyncMapTable.h"
#import "ZXLTaskInfoModel.h"
#import "ZXLDocumentUtils.h"
#import "ZXLNetworkManager.h"
#import "ZXLUploadUnifiedResponese.h"

@interface ZXLUploadTaskManager ()
@property (nonatomic,strong)ZXLSyncMapTable * uploadTaskDelegates;//需要当前界面返回上传结果的代理
@property (nonatomic,strong)ZXLSyncMapTable * uploadTaskBlocks;//需要当前界面返回上传结果的block
@property (nonatomic,strong)ZXLSyncMutableDictionary * uploadTasks;//所有上传任务
@property (nonatomic,strong)NSTimer * timer;//定时检查上传结果返回处理
@end

@implementation ZXLUploadTaskManager

#pragma 懒加载
-(ZXLSyncMapTable * )uploadTaskDelegates{
    if (!_uploadTaskDelegates) {
        _uploadTaskDelegates = [ZXLSyncMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
    }
    return _uploadTaskDelegates;
}

-(ZXLSyncMapTable * )uploadTaskBlocks{
    if (!_uploadTaskBlocks) {
        _uploadTaskBlocks = [ZXLSyncMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    }
    return _uploadTaskBlocks;
}

-(ZXLSyncMutableDictionary * )uploadTasks{
    if (!_uploadTasks) {
        _uploadTasks = [[ZXLSyncMutableDictionary alloc] init];
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
        [ZXLNetworkManager manager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNetWorkStatus) name:ZXLNetworkReachabilityNotification object:nil];
    }
    return self;
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)clearUploadTask{
    BOOL bHaveUpload = [self haveUploadTaskLoading];
    
    if (bHaveUpload) return NO;

    [self.uploadTasks removeAllObjects];
    [self.uploadTaskDelegates removeAllObjects];
    [self.uploadTaskBlocks removeAllObjects];
    
    [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentUploadTaskInfo];
    return YES;
}

-(BOOL)haveUploadTaskLoading{
     BOOL bHaveUpload = NO;
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo) {
            ZXLUploadTaskType taskUploadResult = [taskInfo uploadTaskType];
            if (taskUploadResult == ZXLUploadTaskTranscoding
                || taskUploadResult == ZXLUploadTaskLoading
                || taskUploadResult == ZXLUploadTaskSuccess) {
                bHaveUpload = YES;
                break;
            }
        }
    }
    return bHaveUpload;
}

-(void)refreshNetWorkStatus{
    if ([ZXLNetworkManager manager].networkStatusChange) {
        //无网变有网络
        if ([ZXLNetworkManager manager].networkstatus > ZXLNetworkReachabilityStatusNotReachable) {
            for (NSString *identifier in [self.uploadTasks allKeys]) {
                ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
                if (taskInfo && (taskInfo.resetUploadType&ZXLRestUploadTaskNetwork)) {
                    ZXLUploadTaskType taskUploadResult = [taskInfo uploadTaskType];
                    if (taskUploadResult == ZXLUploadTaskError) {
                        [self startUploadWithUnifiedResponeseForIdentifier:taskInfo.identifier];
                    }
                }
            }
        }else{//有网络变无网络
            for (NSString *identifier in [self.uploadTasks allKeys]) {
                ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
                if (taskInfo) {
                    [taskInfo networkError];
                }
            }
        }
    }
}

-(void)localTaskInfo{
    //读取本地上传结果文件信息
    NSMutableDictionary * tmpUploadTaskInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadTaskInfo];
    if (ISDictionaryValid(tmpUploadTaskInfo)) {
        for (NSString *dictKey in [tmpUploadTaskInfo allKeys]) {
            ZXLTaskInfoModel * taskInfo =  [ZXLTaskInfoModel dictionary:[tmpUploadTaskInfo valueForKey:dictKey]];
            [self.uploadTasks setObject:taskInfo forKey:dictKey];
        }
    }else{
        [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentUploadTaskInfo];
    }
}

-(void)restUploadTaskReStartProcess{
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo && (taskInfo.resetUploadType&ZXLRestUploadTaskProcess)) {
            [self startUploadWithUnifiedResponeseForIdentifier:taskInfo.identifier];
        }
    }
}

/**
 添加上传任务结果回调
 
 @param delegate 代理
 @param identifier 任务唯一值
 */
- (void)addUploadTaskEndResponeseDelegate:(id<ZXLUploadTaskResponeseDelegate>)delegate forIdentifier:(NSString *)identifier{
    if (!delegate || !ISNSStringValid(identifier))return;
    
    [self.uploadTaskDelegates setObject:delegate forKey:identifier];
}

/**
 删除上传任务(建议在界面释放函数中释放identifier)
 
 @param identifier 任务唯一值
 */
- (void)removeTaskForIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return;
    
    if ([self.uploadTaskDelegates objectForKey:identifier]) {
        [self.uploadTaskDelegates removeObjectForKey:identifier];
    }
    
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks objectForKey:identifier];
    if (taskInfo) {
        [taskInfo removeAllUploadFiles];
        [self.uploadTasks removeObjectForKey:identifier];
        if (taskInfo.storageLocal) {
            NSMutableDictionary * tmpUploadTaskInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadTaskInfo];
            [tmpUploadTaskInfo removeObjectForKey:identifier];
            [ZXLDocumentUtils setDictionaryByListName:tmpUploadTaskInfo fileName:ZXLDocumentUploadTaskInfo];
        }
    }
}

- (void)addUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier{
    if (!fileInfo || !ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo addUploadFile:fileInfo];
    }
}

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier{
    if (!fileInfos || fileInfos.count == 0 || !ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo addUploadFiles:fileInfos];
    }
}

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index forIdentifier:(NSString *)identifier{
    if (!fileInfo || !ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo insertUploadFile:fileInfo atIndex:index];
    }
}

- (void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier{
    if (!fileInfos || fileInfos.count == 0 || !ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo insertUploadFilesFirst:fileInfos];
    }
}

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier{
    if (!fileInfo || !ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo replaceUploadFileAtIndex:index withUploadFile:fileInfo];
    }
}

- (void)removeUploadFileAtIndex:(NSUInteger)index forIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return;
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo removeUploadFileAtIndex:index];
    }
}

- (void)removeUploadFile:(NSString *)fileIdentifier forIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(fileIdentifier) || !ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo removeUploadFile:fileIdentifier];
    }
}

- (void)removeAllUploadFilesForIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo removeAllUploadFiles];
    }
}

-(ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return nil;
    
    return [self.uploadTasks objectForKey:identifier];
}

-(ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier create:(BOOL)bCreate{
    if (!ISNSStringValid(identifier)) return nil;
    
    ZXLTaskInfoModel *tempTaskInfo = [self.uploadTasks objectForKey:identifier];
    if (!tempTaskInfo && bCreate) {
        ZXLTaskInfoModel *taskInfo = NewObject(ZXLTaskInfoModel);
        taskInfo.identifier = identifier;
        [self.uploadTasks setObject:taskInfo forKey:identifier];
    }
    
    return [self.uploadTasks objectForKey:identifier];
}

-(void)addUploadTaskInfo:(ZXLTaskInfoModel *)taskInfo{
    if (!taskInfo || !ISNSStringValid(taskInfo.identifier)) return;
    
    if (![self uploadTaskInfoForIdentifier:taskInfo.identifier]) {
        [self.uploadTasks setObject:taskInfo forKey:taskInfo.identifier];
    }
}

- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result{
    if (!ISNSStringValid(fileIdentifier) || [self.uploadTasks count] == 0) return;

    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo) {
            [taskInfo setFileUploadResult:fileIdentifier type:result];
        }
    }
}

-(BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier{
    if (!ISNSStringValid(taskIdentifier) || !ISNSStringValid(fileIdentifier)) return NO;
    
    if ([self.uploadTasks count] == 0) return YES;
    
    BOOL bExistence = NO;
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo && ![taskIdentifier isEqualToString:taskInfo.identifier]) {
            ZXLUploadTaskType taskUploadResult = [taskInfo uploadTaskType];
            if ((taskUploadResult == ZXLUploadTaskTranscoding || taskUploadResult == ZXLUploadTaskLoading) && [taskInfo checkFileInTask:fileIdentifier]) {
                bExistence = YES;
                break;
            }
        }
    }
    return !bExistence;
}

- (void)startUploadWithUnifiedResponeseForIdentifier:(NSString *)identifier{
    [self startUploadWithUnifiedResponeseForIdentifier:identifier resetUpload:ZXLRestUploadTaskNetwork|ZXLRestUploadTaskProcess];
}

- (void)startUploadWithUnifiedResponeseForIdentifier:(NSString *)identifier resetUpload:(ZXLRestUploadTaskType)resetUploadType{
    [self startUploadForIdentifier:identifier responeseDelegate:[ZXLUploadUnifiedResponese manager] resetUpload:resetUploadType complete:nil];
}

- (void)startUploadForIdentifier:(NSString *)identifier{
    [self startUploadForIdentifier:identifier responeseDelegate:nil resetUpload:ZXLRestUploadTaskNone complete:nil];
}

- (void)startUploadForIdentifier:(NSString *)identifier complete:(void (^)(ZXLTaskInfoModel *taskInfo))complete{
    [self startUploadForIdentifier:identifier responeseDelegate:nil resetUpload:ZXLRestUploadTaskNone complete:complete];
}

- (void)startUploadForIdentifier:(NSString *)identifier
               responeseDelegate:(id<ZXLUploadTaskResponeseDelegate>)delegate
                     resetUpload:(ZXLRestUploadTaskType)resetUploadType
                        complete:(ZXLUploadTaskResponseCallback)complete{
    
    if (!ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks objectForKey:identifier];
    if (taskInfo) {
        taskInfo.resetUploadType = resetUploadType;
        taskInfo.completeResponese = NO;
        //返回block存储（返回处理方式允许一种方式返回）
        if (complete) {
            [self.uploadTaskBlocks setObject:complete forKey:identifier];
            
            if ([self.uploadTaskDelegates objectForKey:identifier]) {
                [self.uploadTaskDelegates removeObjectForKey:identifier];
            }
        }
        //返回delegate存储（返回处理方式允许一种方式返回）
        if (delegate) {
            [self addUploadTaskEndResponeseDelegate:delegate forIdentifier:identifier];
            
            if ([self.uploadTaskBlocks objectForKey:identifier]) {
                [self.uploadTaskBlocks removeObjectForKey:identifier];
            }
            
            if (delegate == [ZXLUploadUnifiedResponese manager]) {
                taskInfo.unifiedResponese = YES;
            }
        }
        
        //任务中所有文件开始上传
        [taskInfo startUpload];
    }
    
    if ( !_timer) {
        _timer = [baseNSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(taskUploadProgress) userInfo:nil repeats:YES];
        [_timer fire];
    }
}

-(void)taskUploadProgress{
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo) {
            ZXLUploadTaskType uploadTaskType = [taskInfo uploadTaskType];
            if (!taskInfo.completeResponese && (uploadTaskType == ZXLUploadTaskSuccess || uploadTaskType == ZXLUploadTaskError)) {
                id  delegate  = [self.uploadTaskDelegates objectForKey:taskInfo.identifier];
                if (delegate && [delegate respondsToSelector:@selector(uploadTaskResponese:)]) {
                    taskInfo.completeResponese = YES;
                    [delegate uploadTaskResponese:taskInfo];
                }else{
                    ZXLUploadTaskResponseCallback  complete  = [self.uploadTaskBlocks objectForKey:taskInfo.identifier];
                    if (complete) {
                        taskInfo.completeResponese = YES;
                        complete(taskInfo);
                        
                        [self.uploadTaskBlocks removeObjectForKey:taskInfo.identifier];
                        
                        [self removeTaskForIdentifier:taskInfo.identifier];
                    }
                }
            }
        }
    }
}
@end
