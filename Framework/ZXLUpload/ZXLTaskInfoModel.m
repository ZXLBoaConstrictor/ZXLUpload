//
//  ZXLTaskInfoModel.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLTaskInfoModel.h"
#import "ZXLFileUtils.h"
#import "ZXLPhotosUtils.h"
#import "ZXLUploadDefine.h"
#import "ZXLFileInfoModel.h"
#import "ZXLUploadFileResultCenter.h"
#import "ZXLUploadFileManager.h"
#import "ZXLDocumentUtils.h"
#import "ZXLSyncMutableArray.h"
#import "ZXLUploadFmdb.h"
#import "ZXLCompressManager.h"
#import "ZXLImageRequestManager.h"

@interface ZXLTaskInfoModel ()

/**
 文件上传任务数组
 外部不可调用 添加和删除的时候都要做任务状态判断，否则会影响上传任务结果
 */
@property (nonatomic,strong)ZXLSyncMutableArray * uploadFiles;

@property (nonatomic,assign)ZXLUploadTaskType taskUploadResult;
@end

@implementation ZXLTaskInfoModel

#pragma 懒加载
-(ZXLSyncMutableArray * )uploadFiles{
    if (!_uploadFiles) {
        _uploadFiles = [[ZXLSyncMutableArray alloc] init];
    }
    return _uploadFiles;
}

+(instancetype)dictionary:(NSDictionary *)dictionary{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    if (self = [super init]) {
        self.taskUploadResult   =  ZXLUploadTaskPrepareForUpload;
        self.identifier         =  [dictionary objectForKey:@"identifier"];
        self.completeResponese  =  ([[dictionary objectForKey:@"completeResponese"] integerValue] == 1);
        self.storageLocal       =  ([[dictionary objectForKey:@"storageLocal"] integerValue] == 1);
        self.resetUploadType    =  [[dictionary objectForKey:@"resetUploadType"] integerValue];
        self.unifiedResponese   =  ([[dictionary objectForKey:@"unifiedResponese"] integerValue] == 1);
        self.uploading          =  ([[dictionary objectForKey:@"uploading"] integerValue] == 1);
        NSArray *ayFiles        =  [dictionary objectForKey:@"uploadFiles"];
        for (NSDictionary *fileDict in ayFiles) {
            [self.uploadFiles addObject:[ZXLFileInfoModel dictionary:fileDict]];
        }
    }
    return self;
}

-(void)dealloc{
    [self.uploadFiles removeAllObjects];
    self.uploadFiles = nil;
}

-(NSMutableDictionary *)keyValues{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:_identifier forKey:@"identifier"];
    [dictionary setValue:_unifiedResponese?@"1":@"0" forKey:@"unifiedResponese"];
    [dictionary setValue:_completeResponese?@"1":@"0" forKey:@"completeResponese"];
    [dictionary setValue:_storageLocal?@"1":@"0" forKey:@"storageLocal"];
    [dictionary setValue:_uploading?@"1":@"0" forKey:@"uploading"];
    [dictionary setValue:@(_resetUploadType).stringValue forKey:@"resetUploadType"];
    
    NSMutableArray * ayFileInfo = [NSMutableArray array];
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
            [ayFileInfo addObject:[fileInfo keyValues]];
        }
    }
    [dictionary setValue:ayFileInfo forKey:@"uploadFiles"];
    return dictionary;
}

- (NSInteger)uploadFilesCount{
    return self.uploadFiles.count;
}

-(void)setTaskUploadResult:(ZXLUploadTaskType)taskUploadResult{
    _taskUploadResult = taskUploadResult;
    if (self.uploading && taskUploadResult == ZXLUploadTaskPrepareForUpload) {
        return;
    }
    
    self.uploading = (_taskUploadResult == ZXLUploadTaskTranscoding || _taskUploadResult == ZXLUploadTaskLoading);
}

-(float)uploadProgress{
    float fProgress = 0;
    
    if (self.taskUploadResult == ZXLUploadTaskSuccess || self.taskUploadResult == ZXLUploadTaskError) {
        return 1.0f;
    }
    
    [self uploadTaskType];
    if (self.taskUploadResult < ZXLUploadTaskLoading) {
        return 0;
    }

    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
            ZXLFileInfoModel * tempFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadProgressFileInfo:fileInfo.identifier];
            if (tempFileInfo) {
                fProgress += tempFileInfo.progress;
            }else{
                fProgress += fileInfo.progress;
            }
        }
    }
    return fProgress/[self.uploadFiles count];
}

-(float)compressProgress{
    float fProgress = 0;
    if (self.taskUploadResult == ZXLUploadTaskPrepareForUpload) {
        [self uploadTaskType];
    }
    
    if (self.taskUploadResult == ZXLUploadTaskPrepareForUpload) {
        return fProgress;
    }
    
    if (self.taskUploadResult != ZXLUploadTaskTranscoding) {
        return 1.0f;
    }
    
    NSInteger fCompressFileCount = 0;
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
            if (fileInfo.fileType == ZXLFileTypeVideo) {
                fCompressFileCount ++;
                if (fileInfo.comprssSuccess) {
                    fProgress += 1;
                }else{
                    fProgress += [[ZXLCompressManager manager] compressProgressForIdentifier:fileInfo.identifier];
                }
            }
        }
    }
    return fProgress/fCompressFileCount;
}

-(long long)uploadFileSize{
    long long fileSize = 0;
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
           fileSize += fileInfo.uploadSize;
        }
    }
    return fileSize;
}

- (void)startUpload{
    ZXLUploadTaskType uploadResult = [self uploadTaskType];
    if (uploadResult == ZXLUploadTaskError) {
        [self clearProgress];
    }
    
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload) return;
    
    //本地数据存储(方便App中间杀掉进程，重新上传)
    [self saveRestUploadTaskProcess];
    
    self.uploading = YES;
    
    __block BOOL compressError = NO;
    NSInteger successCount = 0;
    dispatch_group_t group = dispatch_group_create();
    //开始上传文件要经过任务中同文件筛选和所有正在上传文件筛选
    NSMutableArray * needUploadFiles = [NSMutableArray array];
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
            //任务中同文件筛选
            if ([needUploadFiles indexOfObject:fileInfo.identifier] != NSNotFound) {
                continue;
            }
            //所有正在上传文件筛选
            ZXLFileInfoModel * successFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadSuccessFileInfo:fileInfo.identifier];
            ZXLFileInfoModel * progressFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadProgressFileInfo:fileInfo.identifier];
            BOOL fileCompressing = [[ZXLCompressManager manager] checkFileCompressing:fileInfo.identifier];
            //当有上传成功过的信息，不再继续进行压缩上传
            if (successFileInfo) {
                [fileInfo setUploadStateWithTheSame:successFileInfo];
                successCount ++;
                continue;
            }
            
            //当有同文件正在进行上传或正在进行压缩 - 文件不进行上传
            if (progressFileInfo || fileCompressing) {
                [fileInfo setUploadStateWithTheSame:successFileInfo];
                continue;
            }
            if (!successFileInfo && !progressFileInfo && !fileCompressing) {
                //压缩视频
                if (fileInfo.fileType == ZXLFileTypeVideo) {
                    dispatch_group_enter(group);
                    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [fileInfo videoCompress:^(BOOL bResult) {
                            if (!bResult)
                                compressError = YES;
                            dispatch_group_leave(group);
                        }];
                    });
                }
                
                //本地图片处理图片
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
            }
            [needUploadFiles addObject:fileInfo.identifier];
        }
    }
    
    typeof(self) __weak weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        //所有文件都上传成功过
        if (successCount > 0 && successCount == weakSelf.uploadFiles.count) {
            weakSelf.taskUploadResult = ZXLUploadTaskSuccess;
        }else if (compressError){ //任务中有视频文件压缩失败
            weakSelf.taskUploadResult = ZXLUploadTaskError;
        }else{
            if (needUploadFiles.count > 0) {
                for (NSInteger i = 0; i < [weakSelf.uploadFiles count]; i++) {
                    ZXLFileInfoModel *fileInfo = [weakSelf.uploadFiles objectAtIndex:i];
                    if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
                        if ([needUploadFiles indexOfObject:fileInfo.identifier] != NSNotFound) {
                            [[ZXLUploadFileManager manager] taskUploadFile:fileInfo progress:^(float percent) {
                                fileInfo.progress = percent;
                            } complete:^(ZXLFileUploadType nResult, NSString *resultURL) {
                                fileInfo.uploadResult = nResult;
                            }];
                        }
                    }
                }
            }
        }
    });
}

-(ZXLUploadTaskType)uploadTaskType{
    //任务上传完成的结果直接返回
    if (self.taskUploadResult == ZXLUploadTaskSuccess || self.taskUploadResult == ZXLUploadTaskError || !self.uploading)
        return self.taskUploadResult;
    
    if (self.uploadFiles.count == 0)
        return ZXLUploadTaskPrepareForUpload;
    
    BOOL bError = NO;
    BOOL bCompress = NO;
    BOOL bPrepareForUpload = YES;
    NSInteger nSuccessFileCount = 0;
    
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
    
            BOOL fileCompressing = [[ZXLCompressManager manager] checkFileCompressing:fileInfo.identifier];
            if (fileCompressing) {
                fileInfo.progressType = ZXLFileUploadProgressTranscoding;
            }
            
            ZXLFileInfoModel * progressFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadProgressFileInfo:fileInfo.identifier];
            if (progressFileInfo) {
                [fileInfo setUploadStateWithTheSame:progressFileInfo];
            }
            
            switch (fileInfo.progressType) {
                case ZXLFileUploadProgressTranscoding:{
                    bCompress = YES;
                }
                    break;
                case ZXLFileUploadProgressUploadEnd:{
                    if (fileInfo.uploadResult == ZXLFileUploadError || fileInfo.uploadResult == ZXLFileUploadFileError) {
                        bError = YES;
                    }else{
                        nSuccessFileCount ++;
                    }
                }
                    break;
                default:
                    
                    break;
            }
            
            if (fileInfo.progressType != ZXLFileUploadProgressStartUpload) {
                bPrepareForUpload = NO;
            }
        }
    }
    
    if (nSuccessFileCount == self.uploadFiles.count) self.taskUploadResult = ZXLUploadTaskSuccess;
    
    if (bError) self.taskUploadResult = ZXLUploadTaskError;
    
    if (bPrepareForUpload) self.taskUploadResult = ZXLUploadTaskPrepareForUpload;
        
    if (bCompress) self.taskUploadResult = ZXLUploadTaskTranscoding;
    
    if (!bCompress && !bError && !bPrepareForUpload && nSuccessFileCount != self.uploadFiles.count) {
        self.taskUploadResult = ZXLUploadTaskLoading;
    }
    
    return self.taskUploadResult;
}

-(BOOL)beginUpdateFiles{
    //添加上传文件时 确保任务在准备上传状态 -- 上传结束状态要继续添加上传文件清空上传状态，然后再添加文件
    if (self.taskUploadResult == ZXLUploadTaskError || self.taskUploadResult == ZXLUploadTaskSuccess){
        [self clearProgress];
        self.completeResponese = NO;
        self.unifiedResponese = NO;
        self.uploading = NO;
    }
 
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload)
        return NO;
    
    return YES;
}

-(void)addUploadFile:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo || ![self beginUpdateFiles]) return;

    fileInfo.superTaskIdentifier = self.identifier;
    [self.uploadFiles addObject:fileInfo];
}

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos{
    if (!fileInfos || ![self beginUpdateFiles]) return;

    for (ZXLFileInfoModel * fileInfo in fileInfos) {
        [self addUploadFile:fileInfo];
    }
}

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index{
    if (!fileInfo || ![self beginUpdateFiles]) return;
    
    fileInfo.superTaskIdentifier = self.identifier;
    if (self.uploadFiles.count > 0 && index < self.uploadFiles.count) {
        [self.uploadFiles insertObject:fileInfo atIndex:index];
    }else{
        [self.uploadFiles addObject:fileInfo];
    }
}

-(void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos{
    if (!fileInfos || ![self beginUpdateFiles]) return;
    
    if (self.uploadFiles.count > 0) {
        [self.uploadFiles addObjectsFromArrayAtFirst:fileInfos];
    }else{
        [self.uploadFiles addObjectsFromArray:fileInfos];
    }
}

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo || ![self beginUpdateFiles] || index >= self.uploadFiles.count) return;
    
    ZXLFileInfoModel * tempFileInfo = [self.uploadFiles objectAtIndex:index];
    if (tempFileInfo) {
        [tempFileInfo resetFileInfo];
    }

    [self.uploadFiles replaceObjectAtIndex:index withObject:fileInfo];
}

- (void)removeUploadFileAtIndex:(NSUInteger)index{
    if (index >= self.uploadFiles.count || ![self beginUpdateFiles]) return;
    
    [self.uploadFiles removeObjectAtIndex:index];
}

-(void)removeUploadFile:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return;
    
    //只有在上传失败或者是准备上传的情况下才能删除文件信息
    if (self.taskUploadResult == ZXLUploadTaskError || self.taskUploadResult == ZXLUploadTaskPrepareForUpload){
        self.completeResponese = NO;
        self.unifiedResponese = NO;
        self.uploading = NO;
        
        for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
            ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
            if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]] && [fileInfo.identifier isEqualToString:identifier]) {
                [fileInfo resetFileInfo];
                [self.uploadFiles removeObject:fileInfo];
                break;
            }
        }
    }
}

-(void)removeAllUploadFiles{
    if (self.uploadFiles.count == 0) return;
    
    //只有在上传失败或者是准备上传的情况下才能删除文件信息
    if (self.taskUploadResult == ZXLUploadTaskError
        || self.taskUploadResult == ZXLUploadTaskPrepareForUpload
        || self.taskUploadResult == ZXLUploadTaskSuccess){
        [self clearProgress];
        self.completeResponese = NO;
        self.unifiedResponese = NO;
        self.uploading = NO;
        
        [self.uploadFiles removeAllObjects];
    }
}

- (ZXLFileInfoModel *)uploadFileAtIndex:(NSInteger)index{
    
    if (index >= self.uploadFiles.count) return nil;

    return [self.uploadFiles objectAtIndex:index];
}

- (ZXLFileInfoModel *)uploadFileForIdentifier:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return nil;
    
    ZXLFileInfoModel *tempFileInfo = nil;
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]] && [fileInfo.identifier isEqualToString:identifier]) {
            tempFileInfo = fileInfo;
            break;
        }
    }
    return tempFileInfo;
}

- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result{
    if (!ZXLISNSStringValid(fileIdentifier)) return;
    
    if (!self.uploading) return;
    
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]
            && [fileInfo.identifier isEqualToString:fileIdentifier] && fileInfo.uploadResult != result) {
            
            if (result == ZXLFileUploadSuccess) {
                [fileInfo setUploadResultSuccess];
            }
            
            if (result == ZXLFileUploadFileError || result == ZXLFileUploadError) {
                [fileInfo setUploadResultError:result];
            }
        }
    }
}

-(BOOL)checkFileInTask:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier)) return NO;
    
    BOOL bExistence = NO;
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]] && [fileInfo.identifier isEqualToString:identifier]) {
            bExistence = YES;
            break;
        }
    }
    return bExistence;
}

/**
 上传任务保存本地（App 杀进程，重启时仍然可以继续上传）
 */
- (void)saveRestUploadTaskProcess{
    if ((self.resetUploadType&ZXLRestUploadTaskProcess)) {
        if (self.storageLocal) {
            [[ZXLUploadFmdb manager] deleteUploadTaskInfo:self];
        }
        self.storageLocal = YES;
        [[ZXLUploadFmdb manager] insertUploadTaskInfo:self];
    }
}

-(void)clearProgress{
    self.taskUploadResult = ZXLUploadTaskPrepareForUpload;
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
            [fileInfo resetFileInfo];
        }
    }
}

- (void)networkError{
    self.uploading = YES;
    ZXLUploadTaskType taskUploadResult = [self uploadTaskType];
    if (taskUploadResult <= ZXLUploadTaskLoading) {
        for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
            ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
            if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
                [fileInfo networkError];
            }
        }
    }
}

- (NSString *)filesJSONString{
    NSMutableArray * ayFileInfo = [NSMutableArray array];
    for (NSInteger i = 0; i < [self.uploadFiles count]; i++) {
        ZXLFileInfoModel *fileInfo = [self.uploadFiles objectAtIndex:i];
        if (fileInfo && [fileInfo isKindOfClass:[ZXLFileInfoModel class]]) {
            [ayFileInfo addObject:[[fileInfo keyValues] JSONString]];
        }
    }
    return [ayFileInfo JSONString];
}
@end
