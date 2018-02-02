//
//  ZXLTaskInfoModel.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLTaskInfoModel.h"

#import "ZXLFileInfoModel.h"
#import "ZXLUploadFileResultCenter.h"

@interface ZXLTaskInfoModel ()

/**
 文件上传任务数组
 外部不可调用 添加和删除的时候都要做任务状态判断，否则会影响上传任务结果
 */
@property (nonatomic,strong)NSMutableArray<ZXLFileInfoModel *> * uploadFiles;

@property (nonatomic,assign)ZXLUploadTaskType taskUploadResult;
@end

@implementation ZXLTaskInfoModel

#pragma 懒加载
-(NSMutableArray<ZXLFileInfoModel *> * )uploadFiles{
    if (!_uploadFiles) {
        _uploadFiles = [NSMutableArray array];
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
        NSArray *ayFiles        =  [dictionary objectForKey:@"uploadFiles"];
        for (NSDictionary *fileDict in ayFiles) {
            [self.uploadFiles addObject:[ZXLFileInfoModel dictionary:fileDict]];
        }
    }
    return self;
}

-(void)dealloc
{
    [self clearProgress];
    [self.uploadFiles removeAllObjects];
    self.uploadFiles = nil;
}

-(NSMutableDictionary *)keyValues{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:_identifier forKey:@"identifier"];
    
    NSMutableArray * ayFileInfo = [NSMutableArray array];
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
        [ayFileInfo addObject:[fileInfo keyValues]];
    }
    [dictionary setValue:ayFileInfo forKey:@"uploadFiles"];
    return dictionary;
}

-(float)uploadProgress{
    float fProgress = 0;
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
        ZXLFileInfoModel * tempFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadProgressFileInfo:fileInfo.identifier];
        if (tempFileInfo) {
            fProgress += tempFileInfo.progress;
        }else{
            fProgress += fileInfo.progress;
        }
    }
    return fProgress;
}

-(float)compressProgress{
    float fProgress = 0;
    NSInteger fCompressFileCount = 0;
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
        if (fileInfo.fileType == ZXLFileTypeVideo) {
            fCompressFileCount ++;
            AVAssetExportSession *Session = [[ZXLUploadFileResultCenter shareUploadResultCenter] getAVAssetExportSession:fileInfo.identifier];
            if (Session) {
                fProgress += Session.progress;
            }else{
                fProgress += 1.0;
            }
        }
    }
    return fProgress/fCompressFileCount;
}

-(long long)uploadFileSize{
    long long fileSize = 0;
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
        fileSize += fileInfo.uploadSize;
    }
    return fileSize;
}


-(ZXLUploadTaskType)uploadTaskType{
    
    //任务上传完成的结果直接返回
    if (self.taskUploadResult == ZXLUploadTaskSuccess || self.taskUploadResult == ZXLUploadTaskError)
        return self.taskUploadResult;
    
    if (self.uploadFiles.count == 0)
        return ZXLUploadTaskPrepareForUpload;
    
    BOOL bError = NO;
    BOOL bCompress = NO;
    BOOL bPrepareForUpload = YES;
    NSInteger nSuccessFileCount = 0;
    
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
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
    
    if (nSuccessFileCount == self.uploadFiles.count) self.taskUploadResult = ZXLUploadTaskSuccess;
    
    if (bError) self.taskUploadResult = ZXLUploadTaskError;
    
    if (bPrepareForUpload) self.taskUploadResult = ZXLUploadTaskPrepareForUpload;
        
    if (bCompress) self.taskUploadResult = ZXLUploadTaskTranscoding;
    
    return self.taskUploadResult;
}



-(void)addUploadFile:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo) return;
    
    //添加上传文件时 确保文件在准备上传状态 -- 失败状态要继续添加上传文件清空上传状态，然后再添加文件
    if (self.taskUploadResult == ZXLUploadTaskError)
        [self clearProgress];
    
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload)
        return;

    fileInfo.superTaskIdentifier = self.identifier;
    [self.uploadFiles addObject:fileInfo];
}

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos{
    if (!fileInfos) return;
    
    if (self.taskUploadResult == ZXLUploadTaskError)
        [self clearProgress];
    
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload)
        return;
    
    for (ZXLFileInfoModel * fileInfo in fileInfos) {
        [self addUploadFile:fileInfo];
    }
}

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index{
    
    if (!fileInfo) return;
    
    if (self.taskUploadResult == ZXLUploadTaskError)
        [self clearProgress];
    
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload)
        return;
    
    fileInfo.superTaskIdentifier = self.identifier;
    if (self.uploadFiles.count > 0 && index < self.uploadFiles.count) {
        [self.uploadFiles insertObject:fileInfo atIndex:index];
    }else{
        [self.uploadFiles addObject:fileInfo];
    }
}

-(void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos{
    if (!fileInfos) return;
    
    if (self.taskUploadResult == ZXLUploadTaskError)
        [self clearProgress];
    
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload)
        return;
    
    if (self.uploadFiles.count > 0) {
        NSMutableArray<ZXLFileInfoModel *> * arrayTemp = [NSMutableArray arrayWithArray:self.uploadFiles];
        [self.uploadFiles removeAllObjects];
        [self.uploadFiles addObjectsFromArray:fileInfos];
        [self.uploadFiles addObjectsFromArray:arrayTemp];
    }else{
        [self.uploadFiles addObjectsFromArray:fileInfos];
    }
}

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo
{
    if (!fileInfo || index >= self.uploadFiles.count) return;
    
    if (self.taskUploadResult == ZXLUploadTaskError)
        [self clearProgress];
    
    if (self.taskUploadResult != ZXLUploadTaskPrepareForUpload)
        return;
    
    [self.uploadFiles replaceObjectAtIndex:index withObject:fileInfo];
}

-(void)removeUploadFile:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return;
    
    //只有在上传失败或者是准备上传的情况下才能删除文件信息
    if (self.taskUploadResult == ZXLUploadTaskError || self.taskUploadResult == ZXLUploadTaskPrepareForUpload)
    {
        for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
            if ([fileInfo.identifier isEqualToString:identifier]) {
                [self.uploadFiles removeObject:fileInfo];
                break;
            }
        }
    }
}

-(void)removeAllUploadFiles{
    if (self.uploadFiles.count == 0) return;
    
    //只有在上传失败或者是准备上传的情况下才能删除文件信息
    if (self.taskUploadResult == ZXLUploadTaskError || self.taskUploadResult == ZXLUploadTaskPrepareForUpload)
    {
        [self clearProgress];
        [self.uploadFiles removeAllObjects];
    }
}

-(BOOL)checkFileInTask:(NSString *)identifier{
    if (!ISNSStringValid(identifier)) return NO;
    
    BOOL bExistence = NO;
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
        if ([fileInfo.identifier isEqualToString:identifier]) {
            bExistence = YES;
            break;
        }
    }
    return bExistence;
}

-(void)clearProgress{
    self.taskUploadResult = ZXLUploadTaskPrepareForUpload;
    for (ZXLFileInfoModel *fileInfo in self.uploadFiles) {
        [fileInfo resetFileInfo];
    }
}

@end
