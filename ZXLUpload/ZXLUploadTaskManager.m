//
//  ZXLUploadTaskManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadTaskManager.h"
#import "ZXLUploadDefine.h"
#import "ZXLSyncMutableDictionary.h"
#import "ZXLSyncMapTable.h"
#import "ZXLTaskInfoModel.h"
#import "ZXLDocumentUtils.h"
#import "ZXLNetworkManager.h"
#import "ZXLUploadUnifiedResponese.h"
#import "ZXLTimer.h"
#import "ZXLUploadFmdb.h"

@interface ZXLUploadTaskManager ()
@property (nonatomic,strong)ZXLSyncMapTable * uploadTaskDelegates;//需要当前界面返回上传结果的代理
@property (nonatomic,strong)ZXLSyncMapTable * uploadTaskBlocks;//需要当前界面返回上传结果的block
@property (nonatomic,strong)ZXLSyncMapTable * uploadTaskProgressBlocks;//需要当前界面返回上传进度的block
@property (nonatomic,strong)ZXLSyncMapTable * uploadTaskCompressBlocks;//需要当前界面返回压缩进度的block
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

-(ZXLSyncMapTable * )uploadTaskProgressBlocks{
    if (!_uploadTaskProgressBlocks) {
        _uploadTaskProgressBlocks = [ZXLSyncMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    }
    return _uploadTaskProgressBlocks;
}

-(ZXLSyncMapTable * )uploadTaskCompressBlocks{
    if (!_uploadTaskCompressBlocks) {
        _uploadTaskCompressBlocks = [ZXLSyncMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    }
    return _uploadTaskCompressBlocks;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNetWorkStatus) name:ZXLNetworkReachabilityNotification object:nil];
        [ZXLNetworkManager manager];
        [self localTaskInfo];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)clearUploadTask{
    BOOL bHaveUpload = [self haveUploadTaskLoading];
    
    if (bHaveUpload) return NO;
    
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        [self removeTaskForIdentifier:identifier];
    }
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
    //无网变有网络
    if ([ZXLNetworkManager appHaveNetwork]) {
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

-(void)localTaskInfo{
    //读取本地上传结果文件信息
    NSMutableArray <ZXLTaskInfoModel *>*taskModels = [[ZXLUploadFmdb manager] selectAllUploadTaskInfo];
    if (ZXLISArrayValid(taskModels)) {
        [taskModels enumerateObjectsUsingBlock:^(ZXLTaskInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.uploadTasks setObject:obj forKey:obj.identifier];
        }];
    }
}

-(void)restUploadTaskReStartProcess{
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo
            && (taskInfo.resetUploadType&ZXLRestUploadTaskProcess)
            && !taskInfo.completeResponese
            && [taskInfo uploadTaskType] != ZXLUploadTaskSuccess) {
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
    if (!delegate || !ZXLISNSStringValid(identifier))return;
    
    [self.uploadTaskDelegates setObject:delegate forKey:identifier];
}


/**
 清空上传任务状态

 @param identifier 任务唯一值
 */
-(void)clearUploadTaskResponeseForIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return;
    
    //当任务为未做过返回处理的时候不做清空处理
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks objectForKey:identifier];
    if (taskInfo && !taskInfo.completeResponese) {
        return;
    }

    if (taskInfo){
        taskInfo.unifiedResponese = NO;
        taskInfo.completeResponese = NO;
        taskInfo.resetUploadType = ZXLRestUploadTaskNone;
    }
}

/**
 删除上传任务(建议在界面释放函数中释放identifier)
 
 @param identifier 任务唯一值
 */
- (void)removeTaskForIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return;
    
    if ([self.uploadTaskDelegates objectForKey:identifier]) {
        [self.uploadTaskDelegates removeObjectForKey:identifier];
    }
    
    if ([self.uploadTaskBlocks objectForKey:identifier]) {
        [self.uploadTaskBlocks removeObjectForKey:identifier];
    }
    
    if ([self.uploadTaskProgressBlocks objectForKey:identifier]) {
        [self.uploadTaskProgressBlocks removeObjectForKey:identifier];
    }
    
    if ([self.uploadTaskCompressBlocks objectForKey:identifier]) {
        [self.uploadTaskCompressBlocks removeObjectForKey:identifier];
    }
    
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks objectForKey:identifier];
    if (taskInfo) {
        [taskInfo removeAllUploadFiles];
        [self.uploadTasks removeObjectForKey:identifier];
        if (taskInfo.storageLocal) {
            [[ZXLUploadFmdb manager] deleteUploadTaskInfo:taskInfo];
        }
    }
}

- (void)addUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier{
    if (!fileInfo || !ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo addUploadFile:fileInfo];
    }
}

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier{
    if (!fileInfos || fileInfos.count == 0 || !ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo addUploadFiles:fileInfos];
    }
}

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index forIdentifier:(NSString *)identifier{
    if (!fileInfo || !ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo insertUploadFile:fileInfo atIndex:index];
    }
}

- (void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier{
    if (!fileInfos || fileInfos.count == 0 || !ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo insertUploadFilesFirst:fileInfos];
    }
}

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier{
    if (!fileInfo || !ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo replaceUploadFileAtIndex:index withUploadFile:fileInfo];
    }
}

- (void)removeUploadFileAtIndex:(NSUInteger)index forIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return;
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo removeUploadFileAtIndex:index];
    }
}

- (void)removeUploadFile:(NSString *)fileIdentifier forIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(fileIdentifier) || !ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo removeUploadFile:fileIdentifier];
    }
}

- (void)removeAllUploadFilesForIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self uploadTaskInfoForIdentifier:identifier create:YES];
    if (taskInfo) {
        [taskInfo removeAllUploadFiles];
    }
}

-(ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return nil;
    
    return [self.uploadTasks objectForKey:identifier];
}

-(ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier create:(BOOL)bCreate{
    if (!ZXLISNSStringValid(identifier)) return nil;
    
    ZXLTaskInfoModel *tempTaskInfo = [self.uploadTasks objectForKey:identifier];
    if (!tempTaskInfo && bCreate) {
        ZXLTaskInfoModel *taskInfo = ZXLNewObject(ZXLTaskInfoModel);
        taskInfo.identifier = identifier;
        [self.uploadTasks setObject:taskInfo forKey:identifier];
    }
    
    return [self.uploadTasks objectForKey:identifier];
}

-(void)addUploadTaskInfo:(ZXLTaskInfoModel *)taskInfo{
    if (!taskInfo || !ZXLISNSStringValid(taskInfo.identifier)) return;
    
    if (![self uploadTaskInfoForIdentifier:taskInfo.identifier]) {
        [self.uploadTasks setObject:taskInfo forKey:taskInfo.identifier];
    }
}

- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result{
    if (!ZXLISNSStringValid(fileIdentifier) || [self.uploadTasks count] == 0) return;

    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo) {
            [taskInfo setFileUploadResult:fileIdentifier type:result];
        }
    }
}

-(BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier{
    if (!ZXLISNSStringValid(taskIdentifier) || !ZXLISNSStringValid(fileIdentifier)) return NO;
    
    if ([self.uploadTasks count] == 0) return YES;
    
    BOOL bExistence = NO;
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo && ![taskIdentifier isEqualToString:taskInfo.identifier] && [taskInfo checkFileInTask:fileIdentifier]) {
            ZXLUploadTaskType taskUploadResult = [taskInfo uploadTaskType];
            if (taskUploadResult == ZXLUploadTaskTranscoding || taskUploadResult == ZXLUploadTaskLoading) {
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
    [self startUploadForIdentifier:identifier responeseDelegate:[ZXLUploadUnifiedResponese manager] resetUpload:resetUploadType compress:nil progress:nil complete:nil];
}

- (void)startUploadForIdentifier:(NSString *)identifier{
    [self startUploadForIdentifier:identifier responeseDelegate:nil resetUpload:ZXLRestUploadTaskNone compress:nil progress:nil complete:nil];
}

- (void)startUploadForIdentifier:(NSString *)identifier
                        compress:(ZXLUploadTaskCompressCallback)compress
                        progress:(ZXLUploadTaskProgressCallback)progress
                        complete:(ZXLUploadTaskResponseCallback)complete{
    [self startUploadForIdentifier:identifier responeseDelegate:nil resetUpload:ZXLRestUploadTaskNone compress:compress progress:progress complete:complete];
}

- (void)startUploadForIdentifier:(NSString *)identifier
               responeseDelegate:(id<ZXLUploadTaskResponeseDelegate>)delegate
                     resetUpload:(ZXLRestUploadTaskType)resetUploadType
                        compress:(ZXLUploadTaskCompressCallback)compress
                        progress:(ZXLUploadTaskProgressCallback)progress
                        complete:(ZXLUploadTaskResponseCallback)complete{
    
    if (!ZXLISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks objectForKey:identifier];
    if (taskInfo) {
        //文件任务完成过成功结果返回时处理（由于上传结果删除时只是做了代理、block、存储删除，上传结果并未做处理，等App进程干掉或者清空缓存时才删除）
        if ((taskInfo.completeResponese && [taskInfo uploadTaskType] == ZXLUploadTaskSuccess)
            ||([taskInfo uploadTaskType] == ZXLUploadTaskError && ![ZXLNetworkManager appHaveNetwork])) {
            id checkDelegate = delegate;
            if (checkDelegate && [checkDelegate respondsToSelector:@selector(uploadTaskResponese:)]) {
                if (checkDelegate == [ZXLUploadUnifiedResponese manager]) {
                    taskInfo.unifiedResponese = YES;
                }
                taskInfo.completeResponese = YES;
                [checkDelegate uploadTaskResponese:taskInfo];
            }else{
                if (complete) {
                    taskInfo.completeResponese = YES;
                    complete(taskInfo);
                }
            }
            return;
        }
        
        //此任务已经开始的时候直接返回
        if ([taskInfo uploadTaskType] == ZXLUploadTaskTranscoding || [taskInfo uploadTaskType] == ZXLUploadTaskLoading) {
            return;
        }
        
        taskInfo.resetUploadType = resetUploadType;
        taskInfo.completeResponese = NO;
        //任务压缩进度block
        if (compress) {
            [self.uploadTaskCompressBlocks setObject:compress forKey:identifier];
        }
        
        //任务上传进度block
        if (progress) {
            [self.uploadTaskProgressBlocks setObject:progress forKey:identifier];
        }
        
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
        if ([ZXLNetworkManager appHaveNetwork]) {
            [taskInfo startUpload];
        }else{
            [taskInfo networkError];
        }
    }
    
    if ( !_timer) {
        _timer = [ZXLTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(taskUploadProgress) userInfo:nil repeats:YES];
        [_timer fire];
    }
}

-(void)taskUploadProgress{
    for (NSString *identifier in [self.uploadTasks allKeys]) {
        ZXLTaskInfoModel *taskInfo = [self.uploadTasks objectForKey:identifier];
        if (taskInfo) {
            ZXLUploadTaskType uploadTaskType = [taskInfo uploadTaskType];
            //任务压缩进度block 返回
            if (uploadTaskType == ZXLUploadTaskTranscoding) {
                ZXLUploadTaskCompressCallback  compress  = [self.uploadTaskCompressBlocks objectForKey:taskInfo.identifier];
                if (compress) {
                    compress([taskInfo compressProgress]);
                }
                continue;
            }
            //任务上传进度block返回
            if (uploadTaskType == ZXLUploadTaskLoading) {
                ZXLUploadTaskProgressCallback  progress  = [self.uploadTaskProgressBlocks objectForKey:taskInfo.identifier];
                if (progress) {
                    progress([taskInfo uploadProgress]);
                }
                continue;
            }
            //任务上传结果返回
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
                    }
                }
            }
        }
    }
}
@end
