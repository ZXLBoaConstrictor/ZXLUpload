//
//  ZXLUploadFileResultCenter.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadFileResultCenter.h"
#import "ZXLUploadDefine.h"
#import "ZXLSyncMutableDictionary.h"
#import "ZXLDocumentUtils.h"
#import "ZXLFileInfoModel.h"
#import "ZXLUploadTaskManager.h"
#import "ZXLUploadTaskManager.h"
#import "ZXLUploadFmdb.h"
#import "ZXLCompressManager.h"
#import "ZXLImageRequestManager.h"

@interface ZXLUploadFileResultCenter()

/**
 上传文件信息 -- 保存本地
 */
@property(nonatomic,strong)ZXLSyncMutableDictionary * uploadResultInfo;

/**
 压缩文件信息 -- 保存本地
 */
@property(nonatomic,strong)ZXLSyncMutableDictionary * comprssResultInfo;


/**
 文件上传失败信息
 */
@property(nonatomic,strong)ZXLSyncMutableDictionary * uploadErrorInfo;

/**
 上传过程中的文件信息
 */
@property(nonatomic,strong)ZXLSyncMutableDictionary * uploadInfo;

/**
  上传 session 任务
 */
@property(nonatomic,strong)ZXLSyncMutableDictionary * sessionRequestDict;

@end

@implementation ZXLUploadFileResultCenter
+(ZXLUploadFileResultCenter*)shareUploadResultCenter{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadFileResultCenter * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadFileResultCenter alloc] initLoadLocalUploadInfo];
    });
    return _sharedObject;
}

- (instancetype)initLoadLocalUploadInfo{
     if (self = [super init]) {
         
         _uploadResultInfo = [[ZXLSyncMutableDictionary alloc] init];
         _uploadErrorInfo = [[ZXLSyncMutableDictionary alloc] init];
         _comprssResultInfo = [[ZXLSyncMutableDictionary alloc] init];
         _uploadInfo = [[ZXLSyncMutableDictionary alloc] init];
         _sessionRequestDict = [[ZXLSyncMutableDictionary alloc] init];
         
         //读取本地上传结果文件信息
         NSMutableArray<ZXLFileInfoModel *> *fileModels =[[ZXLUploadFmdb manager] selectAllUploadSuccessFileResultInfo];
         if (ZXLISArrayValid(fileModels)) {
             [fileModels enumerateObjectsUsingBlock:^(ZXLFileInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 [self.uploadResultInfo setObject:obj forKey:obj.identifier];
             }];
         }
         
         //读取压缩成功的文件信息 并检查压缩成功的文件是否还在本地
         NSMutableArray<ZXLFileInfoModel *> *compressFileModels =[[ZXLUploadFmdb manager] selectAllCompressFileInfo];
         if (ZXLISArrayValid(compressFileModels)) {
             [compressFileModels enumerateObjectsUsingBlock:^(ZXLFileInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 NSString * videoName = [obj uploadKey];
                 NSString * comprssURL = FILE_Video_PATH(videoName);
                 if (obj.comprssSuccess && [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
                     [self.comprssResultInfo setObject:obj forKey:obj.identifier];
                 }else{
                     [[ZXLUploadFmdb manager] deleteCompressFileInfo:obj];
                 }
             }];
         }
     }
    return self;
}

-(BOOL)clearAllUploadFileInfo{
    if ([[ZXLUploadTaskManager manager] haveUploadTaskLoading]) {
        return NO;
    }
    
    [_uploadResultInfo removeAllObjects];
    [_comprssResultInfo removeAllObjects];
    [_uploadInfo removeAllObjects];
    [_uploadErrorInfo removeAllObjects];
    [_sessionRequestDict removeAllObjects];
    [[ZXLUploadFmdb manager] clearUploadSuccessFileResultInfo];
    [[ZXLUploadFmdb manager] clearCompressFileInfo];
    return YES;
}


-(void)saveComprssSuccess:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo || fileInfo.fileType != ZXLFileTypeVideo) return;
    
    NSString * videoName = [fileInfo uploadKey];
    NSString * comprssURL = FILE_Video_PATH(videoName);
    if (![self checkComprssSuccessFileInfo:fileInfo.identifier] && //检查此文件是否保存过
        fileInfo.comprssSuccess &&  //检查压缩成功后的地址和压缩后的文件是否存在
        [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
        
        //压缩成功存储记录
        [[ZXLUploadFmdb manager] insertCompressFileInfo:fileInfo];
        //存储成功记录
        [_comprssResultInfo setObject:[ZXLFileInfoModel dictionary:[fileInfo keyValues]] forKey:fileInfo.identifier];
    }
}

-(void)saveUploadSuccess:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo) return;
    
    //检查此文件是否保存过和文件是否上传成功
    if (![self checkUploadSuccessFileInfo:fileInfo.identifier]&&
        fileInfo.progressType == ZXLFileUploadProgressUploadEnd &&
        fileInfo.uploadResult == ZXLFileUploadSuccess) {
        //删除压缩成功信息
        if (fileInfo.fileType == ZXLFileTypeVideo) {
            //压缩成功信息删除--内存
            [_comprssResultInfo removeObjectForKey:fileInfo.identifier];
            //压缩成功信息删除--本地
            [[ZXLUploadFmdb manager] deleteCompressFileInfo:fileInfo];
        }
        //删除本地缓存的文件(注图片不做文件删除)
        NSString *filePath = [fileInfo localUploadURL];
        if (ZXLISNSStringValid(filePath) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            BOOL bRemove = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            if (bRemove) {
                
            }
        }
        //删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.identifier];
        //删除上传信息
        [self removeUploadRequest:fileInfo.identifier];
        //存储成功记录--本地
        [[ZXLUploadFmdb manager] insertUploadSuccessFileResultInfo:fileInfo];
        //存储成功记录--内存
        [_uploadResultInfo setObject:[ZXLFileInfoModel dictionary:[fileInfo keyValues]] forKey:fileInfo.identifier];
        //设置所有任务上传的同文件都成功
        [[ZXLUploadTaskManager manager] setFileUploadResult:fileInfo.identifier type:ZXLFileUploadSuccess];
    }
}

-(void)saveUploadError:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo) return;
   
    //删除上传任务
    [self removeFileInfoUpload:fileInfo.identifier];
    
    ZXLFileInfoModel *tempFileInfo = [_uploadErrorInfo objectForKey:fileInfo.identifier];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_uploadErrorInfo setObject:tempFileInfo forKey:tempFileInfo.identifier];
    }
}

/**
 保存文件上传过程信息
 
 @param fileInfo 文件信息
 */
-(void)saveUploadProgress:(ZXLFileInfoModel *)fileInfo{
    ZXLFileInfoModel *tempFileInfo = [_uploadInfo objectForKey:fileInfo.identifier];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_uploadInfo setObject:tempFileInfo forKey:tempFileInfo.identifier];
        //文件开始上传的时候先删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.identifier];
    }else{
        tempFileInfo.progress = fileInfo.progress;
        tempFileInfo.progressType = ZXLFileUploadProgressUpload;
    }
}

-(ZXLFileInfoModel *)checkComprssSuccessFileInfo:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier))  return nil;
    
    ZXLFileInfoModel *fileInfo = [_comprssResultInfo objectForKey:identifier];
    if (fileInfo) {
        NSString * videoName = [fileInfo uploadKey];
        NSString * comprssURL = FILE_Video_PATH(videoName);
        //文件存在返回结果
        if (fileInfo.comprssSuccess && [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
            return fileInfo;
        }else{
            [_comprssResultInfo removeObjectForKey:identifier];
            //文件不存在删除保存过的文件信息
            [[ZXLUploadFmdb manager] deleteCompressFileInfo:fileInfo];
        }
    }
    return nil;
}

-(ZXLFileInfoModel *)checkUploadSuccessFileInfo:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier))  return nil;
    
    ZXLFileInfoModel *fileInfo = [_uploadResultInfo objectForKey:identifier];
    if (fileInfo) {
        if (fileInfo.progressType == ZXLFileUploadProgressUploadEnd && fileInfo.uploadResult == ZXLFileUploadSuccess) {
            return fileInfo;
        }else{
            [_uploadResultInfo removeObjectForKey:identifier];
            //删除保存过但是错误的文件信息
            [[ZXLUploadFmdb manager] deleteUploadSuccessFileResultInfo:fileInfo];
        }
    }
    return nil;
}

/**
 检查文件是否正在上传
 
 @param identifier 文件identifier唯一值
 @return 上传中的文件信息
 */
-(ZXLFileInfoModel *)checkUploadProgressFileInfo:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier))  return nil;
    
    return [_uploadInfo objectForKey:identifier];
}

/**
 检查文件是否上传失败过
 
 @param identifier 文件identifier唯一值
 @return 上传失败过的文件信息
 */
-(ZXLFileInfoModel *)checkUploadErrorFileInfo:(NSString *)identifier{
    if (!ZXLISNSStringValid(identifier))  return nil;
    
    return [_uploadErrorInfo objectForKey:identifier];
}

/**
 添加文件上传Request
 
 @param request Request
 */
-(void)addUploadRequest:(id)request with:(NSString *)identifier{
    if (request && ZXLISNSStringValid(identifier)) {
        [_sessionRequestDict setObject:request forKey:identifier];
    }
}

/**
 删除文件上传Request
 
 @param identifier 文件identifier
 */
-(void)removeUploadRequest:(NSString *)identifier{
    if (ZXLISNSStringValid(identifier)) {
        id request = [_sessionRequestDict objectForKey:identifier];
        if (request) {
            //注意:此处停止上传请求
            if ([request respondsToSelector:@selector(cancel)]) {
                [request cancel];
            }
            
            [_sessionRequestDict removeObjectForKey:identifier];
        }
        //删除正在上传记录
        [_uploadInfo removeObjectForKey:identifier];
    }
}

/**
 删除此文件在上传中留下的不成功的所有信息
 
 @param identifier 文件identifier
 */
-(void)removeFileInfoUpload:(NSString *)identifier{
    //删除压缩
    [[ZXLCompressManager manager] cancelCompressOperationForIdentifier:identifier];
    //删除图片获取
    [[ZXLImageRequestManager manager] cancelImageRequestOperationForIdentifier:identifier];
    //删除上传请求
    [self removeUploadRequest:identifier];
    //删除出错历史
    [_uploadErrorInfo removeObjectForKey:identifier];
}

- (void)networkError{
    //中断所有压缩
    [[ZXLCompressManager manager] cancelCompressOperations];
    //中断所有获取图片
    [[ZXLImageRequestManager manager] cancelImageRequestOperations];
    //中断所有上传
    NSArray * ayIdentifier = [_sessionRequestDict allKeys];
    for (NSString *identifier in ayIdentifier) {
        [self removeUploadRequest:identifier];
    }
}
@end
