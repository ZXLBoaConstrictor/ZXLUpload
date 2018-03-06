//
//  ZXLUploadTaskManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadTaskManager.h"
#import "ZXLTimer.h"
#import "ZXLTaskInfoModel.h"
#import "ZXLDocumentUtils.h"
#import "ZXLNetworkManager.h"

@interface ZXLUploadTaskManager ()
@property (nonatomic,strong)NSMapTable * uploadTaskDelegates;//需要当前界面返回上传结果的代理
@property (nonatomic,strong)NSMutableArray * responeseTags; //标记上传结果做过代理应答（应答过不再应答）
@property (nonatomic,strong)NSMutableArray * localTags; //标记启动过开始的上传任务
@property (nonatomic,strong)NSMutableDictionary * uploadTasks;//所有上传任务
@property (nonatomic,strong)NSTimer * timer;
@end

@implementation ZXLUploadTaskManager

#pragma 懒加载
-(NSMapTable * )uploadTaskDelegates{
    if (!_uploadTaskDelegates) {
        _uploadTaskDelegates = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn
                                                     valueOptions:NSMapTableWeakMemory];
    }
    return _uploadTaskDelegates;
}

-(NSMutableDictionary * )uploadTasks{
    if (!_uploadTasks) {
        _uploadTasks = [NSMutableDictionary dictionary];
    }
    return _uploadTasks;
}

-(NSMutableArray * )localTags{
    if (!_localTags) {
        _localTags = [NSMutableArray array];
    }
    return _localTags;
}

-(NSMutableArray * )responeseTags{
    if (!_responeseTags) {
        _responeseTags = [NSMutableArray array];
    }
    return _responeseTags;
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

-(void)refreshNetWorkStatus
{
    if ([ZXLNetworkManager manager].networkStatusChange) {
        //无网变有网络
        if ([ZXLNetworkManager manager].networkstatus > ZXLNetworkReachabilityStatusNotReachable) {
            
        }else//有网络变无网络
        {
            
        }
    }
}

-(void)localTaskInfo{
    //读取本地上传结果文件信息
    NSMutableDictionary * tmpUploadTaskInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadTaskInfo];
    if (ISDictionaryValid(tmpUploadTaskInfo)) {
        for (NSString *dictKey in [tmpUploadTaskInfo allKeys]) {
            [self.uploadTasks setValue:[ZXLTaskInfoModel dictionary:[tmpUploadTaskInfo valueForKey:dictKey]] forKey:dictKey];
        }
        
        [self.localTags addObjectsFromArray:[tmpUploadTaskInfo allKeys]];
    }else{
        [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentUploadTaskInfo];
    }
}

- (void)addUploadTaskEndResponeseDelegate:(id<ZXLUploadTaskResponeseDelegate>)delegate forIdentifier:(NSString *)identifier{
    if (!delegate || !ISNSStringValid(identifier))return;
    
    if (![self.uploadTaskDelegates objectForKey:identifier]) {
        [self.uploadTaskDelegates setObject:delegate forKey:identifier];
    }
}

- (void)removeTaskForIdentifier:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return;
    
    if ([self.uploadTaskDelegates objectForKey:identifier]) {
        [self.uploadTaskDelegates removeObjectForKey:identifier];
    }
    
    if ([self.responeseTags indexOfObject:identifier] != NSNotFound) {
        [self.responeseTags removeObject:identifier];
    }
    
    if ([self.localTags indexOfObject:identifier] != NSNotFound) {
        [self.localTags removeObject:identifier];
        
        NSMutableDictionary * tmpUploadTaskInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadTaskInfo];
        [tmpUploadTaskInfo removeObjectForKey:identifier];
        [ZXLDocumentUtils setDictionaryByListName:tmpUploadTaskInfo fileName:ZXLDocumentUploadTaskInfo];
    }
    
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks valueForKey:identifier];
    if (taskInfo) {
        [taskInfo removeAllUploadFiles];
        [self.uploadTasks removeObjectForKey:identifier];
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
    
    return [self.uploadTasks valueForKey:identifier];
}

-(ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier create:(BOOL)bCreate{
    if (!ISNSStringValid(identifier)) return nil;
    
    ZXLTaskInfoModel *tempTaskInfo = [self.uploadTasks valueForKey:identifier];
    if (!tempTaskInfo && bCreate) {
        ZXLTaskInfoModel *taskInfo = NewObject(ZXLTaskInfoModel);
        taskInfo.identifier = identifier;
        [self.uploadTasks setValue:taskInfo forKey:identifier];
    }
    
    return [self.uploadTasks valueForKey:identifier];
}

-(void)addUploadTaskInfo:(ZXLTaskInfoModel *)taskInfo{
    if (!taskInfo || !ISNSStringValid(taskInfo.identifier)) return;
    
    if (![self uploadTaskInfoForIdentifier:taskInfo.identifier]) {
        [self.uploadTasks setValue:taskInfo forKey:taskInfo.identifier];
    }
}

- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result{
    if (!ISNSStringValid(fileIdentifier) || self.uploadTasks.count == 0) return;

    for (ZXLTaskInfoModel *taskInfo in [self.uploadTasks allValues]) {
        [taskInfo setFileUploadResult:fileIdentifier type:result];
    }
}

-(BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier{
    if (!ISNSStringValid(taskIdentifier) || !ISNSStringValid(fileIdentifier)) return NO;
    
    if (self.uploadTasks.count == 0) return YES;
    
    BOOL bExistence = NO;
    for (ZXLTaskInfoModel *taskInfo in [self.uploadTasks allValues]) {
        if (![taskIdentifier isEqualToString:taskInfo.identifier]) {
            ZXLUploadTaskType taskUploadResult = [taskInfo uploadTaskType];
            if ((taskUploadResult == ZXLUploadTaskTranscoding || taskUploadResult == ZXLUploadTaskLoading) && [taskInfo checkFileInTask:fileIdentifier]) {
                bExistence = YES;
                break;
            }
        }
    }
    return !bExistence;
}

- (void)startUploadForIdentifier:(NSString *)identifier resetUpload:(BOOL)bResetUpload{
    if (!ISNSStringValid(identifier)) return;
    
    ZXLTaskInfoModel * taskInfo = [self.uploadTasks valueForKey:identifier];
    if (taskInfo) {
        taskInfo.resetUpload = bResetUpload;
        [taskInfo startUpload];
        [self.responeseTags removeObject:taskInfo.identifier];
        
        if ([self.localTags indexOfObject:identifier] != NSNotFound) {
            [self.localTags addObject:identifier];
            
            NSMutableDictionary * tmpUploadTaskInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadTaskInfo];
            [tmpUploadTaskInfo setValue:[taskInfo keyValues] forKey:identifier];
            [ZXLDocumentUtils setDictionaryByListName:tmpUploadTaskInfo fileName:ZXLDocumentUploadTaskInfo];
        }
        
    }
    
    if (self.uploadTasks.count == 1) {
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        
        _timer = [ZXLTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(taskUploadProgress) userInfo:nil repeats:YES];
        [_timer fire];
    }
}

-(void)taskUploadProgress{
    for (ZXLTaskInfoModel *taskInfo in [self.uploadTasks allValues]) {
        ZXLUploadTaskType uploadTaskType = [taskInfo uploadTaskType];
        if ([self.responeseTags indexOfObject:taskInfo.identifier] == NSNotFound && (uploadTaskType == ZXLUploadTaskSuccess || uploadTaskType == ZXLUploadTaskError)) {
            id  delegate  = [self.uploadTaskDelegates objectForKey:taskInfo.identifier];
            if (delegate && [delegate respondsToSelector:@selector(uploadTaskResponese:)]) {
                [delegate uploadTaskResponese:taskInfo];
                [self.responeseTags addObject:taskInfo.identifier];
            }
        }
    }
}

-(void)testReUpload{
    for (ZXLTaskInfoModel *taskInfo in [self.uploadTasks allValues]){
        [self startUploadForIdentifier:taskInfo.identifier resetUpload:YES];
    }
}
@end
