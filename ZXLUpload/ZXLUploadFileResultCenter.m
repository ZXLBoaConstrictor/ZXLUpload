//
//  ZXLUploadFileResultCenter.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadFileResultCenter.h"
#import "ZXLDocumentUtils.h"
#import "ZXLFileInfoModel.h"
#import "ZXLUploadTaskManager.h"

@interface ZXLUploadFileResultCenter()

/**
 上传文件信息 -- 保存本地
 */
@property(nonatomic,strong)NSMutableDictionary * uploadResultInfo;

/**
 压缩文件信息 -- 保存本地
 */
@property(nonatomic,strong)NSMutableDictionary * comprssResultInfo;


/**
 文件上传失败信息
 */
@property(nonatomic,strong)NSMutableDictionary * uploadErrorInfo;

/**
 上传过程中的文件信息
 */
@property(nonatomic,strong)NSMutableDictionary * uploadInfo;

/**
 压缩过程中的文件信息
 */
@property(nonatomic,strong)NSMutableDictionary * comprssInfo;

/**
 文件压缩session
 */
@property(nonatomic,strong)NSMutableDictionary * assetSessionDict;

/**
  上传 session 任务
 */
@property(nonatomic,strong)NSMutableDictionary * sessionRequestDict;

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
         
         _uploadResultInfo = [NSMutableDictionary dictionary];
         _uploadErrorInfo = [NSMutableDictionary dictionary];
         _comprssResultInfo = [NSMutableDictionary dictionary];
         _uploadInfo = [NSMutableDictionary dictionary];
         _comprssInfo = [NSMutableDictionary dictionary];
         _assetSessionDict = [NSMutableDictionary dictionary];
         _sessionRequestDict = [NSMutableDictionary dictionary];
         
         //读取本地上传结果文件信息
         NSMutableDictionary * tmpUploadInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadResultInfo];
         if (ISDictionaryValid(tmpUploadInfo)) {
             [tmpUploadInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                 [_uploadResultInfo setValue:[ZXLFileInfoModel dictionary:(NSDictionary *)obj] forKey:key];
             }];
         }else{
             if (!tmpUploadInfo) {
                [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentUploadResultInfo];
             }
         }
         
         //读取压缩成功的文件信息 并检查压缩成功的文件是否还在本地
         NSMutableDictionary *tempcomprssInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentComprssInfo];
         if (ISDictionaryValid(tempcomprssInfo)) {
             for (NSString * strKey in tempcomprssInfo.allKeys) {
                 NSDictionary * obj = [tempcomprssInfo objectForKey:strKey];
                 if (ISDictionaryValid(obj)) {
                     ZXLFileInfoModel *fileInfo =  [ZXLFileInfoModel dictionary:(NSDictionary *)obj];
                     NSString * videoName = [fileInfo uploadKey];
                     NSString * comprssURL = FILE_Video_PATH(videoName);
                     if (fileInfo.comprssSuccess && [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
                         [_comprssResultInfo setValue:fileInfo forKey:strKey];
                     }else
                     {
                         [tempcomprssInfo removeObjectForKey:strKey];
                     }
                 }
             }
         }else{
             if (!tempcomprssInfo) {
                 [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentComprssInfo];
             }
         }
     }
    return self;
}

-(void)clearAllUploadFileInfo{
    [_uploadResultInfo removeAllObjects];
    [_comprssResultInfo removeAllObjects];
    [_uploadInfo removeAllObjects];
    [_comprssInfo removeAllObjects];
    [_assetSessionDict removeAllObjects];
    [_uploadErrorInfo removeAllObjects];
    [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentUploadResultInfo];
    [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentComprssInfo];
}


-(void)saveComprssSuccess:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo || fileInfo.fileType != ZXLFileTypeVideo) return;
    
    NSString * videoName = [fileInfo uploadKey];
    NSString * comprssURL = FILE_Video_PATH(videoName);
    if (![self checkComprssSuccessFileInfo:fileInfo.identifier] && //检查此文件是否保存过
        fileInfo.comprssSuccess &&  //检查压缩成功后的地址和压缩后的文件是否存在
        [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
        
        NSMutableDictionary *tempcomprssInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentComprssInfo];
        [tempcomprssInfo setValue:[fileInfo keyValues] forKey:fileInfo.identifier];
        [ZXLDocumentUtils setDictionaryByListName:tempcomprssInfo fileName:ZXLDocumentComprssInfo];
        
        ZXLFileInfoModel * tempFileInfo = [ZXLFileInfoModel dictionary:[tempcomprssInfo valueForKey:fileInfo.identifier]];
        //存储成功记录
        [_comprssResultInfo setValue:tempFileInfo forKey:fileInfo.identifier];
        
        //压缩成功后把压缩过程存的文件信息删除
        [self removeFileAVAssetExportSession:fileInfo.identifier];
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
            NSMutableDictionary *tempcomprssInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentComprssInfo];
            [tempcomprssInfo removeObjectForKey:fileInfo.identifier];
            [ZXLDocumentUtils setDictionaryByListName:tempcomprssInfo fileName:ZXLDocumentComprssInfo];
        }
        //删除本地缓存的文件(注图片不做文件删除)
        if (fileInfo.fileType != ZXLFileTypeImage) {
            NSString *filePath = [fileInfo localUploadURL];
            if (ISNSStringValid(filePath) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                BOOL bRemove = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                if (bRemove) {
                    
                }
            }
        }
        //删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.identifier];
        //删除上传信息
        [self removeUploadRequest:fileInfo.identifier];
        //存储成功记录--本地
        NSMutableDictionary * tmpUploadInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadResultInfo];
        [tmpUploadInfo setValue:[fileInfo keyValues] forKey:fileInfo.identifier];
        [ZXLDocumentUtils setDictionaryByListName:tmpUploadInfo fileName:ZXLDocumentUploadResultInfo];
        //存储成功记录--内存
        ZXLFileInfoModel * tempFileInfo = [ZXLFileInfoModel dictionary:[tmpUploadInfo valueForKey:fileInfo.identifier]];
        [_uploadResultInfo setValue:tempFileInfo forKey:fileInfo.identifier];
        //设置所有任务上传的同文件都成功
        [[ZXLUploadTaskManager manager] setFileUploadResult:fileInfo.identifier type:ZXLFileUploadSuccess];
    }
}

-(void)saveUploadError:(ZXLFileInfoModel *)fileInfo{
    if (!fileInfo) return;
    
    ZXLFileInfoModel *tempFileInfo = [_uploadErrorInfo valueForKey:fileInfo.identifier];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_uploadErrorInfo setValue:tempFileInfo forKey:tempFileInfo.identifier];
        
        //删除上传任务
        [self removeUploadRequest:fileInfo.identifier];
    }
}

/**
 保存文件压缩过程信息
 
 @param fileInfo 文件信息
 */
-(void)saveComprssProgress:(ZXLFileInfoModel *)fileInfo ExportSession:(AVAssetExportSession *)session{
    if (!fileInfo || !session ||fileInfo.fileType != ZXLFileTypeVideo) return;
    
    ZXLFileInfoModel *tempFileInfo = [_comprssInfo valueForKey:fileInfo.identifier];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_comprssInfo setValue:tempFileInfo forKey:tempFileInfo.identifier];
        
        //文件开始压缩的时候先删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.identifier];
        //保存session
        [self addFileAVAssetExportSession:session with:fileInfo.identifier];
        
    }else
    {
        tempFileInfo.progress = fileInfo.progress;
        tempFileInfo.progressType = ZXLFileUploadProgressTranscoding;
    }
}


/**
 保存文件上传过程信息
 
 @param fileInfo 文件信息
 */
-(void)saveUploadProgress:(ZXLFileInfoModel *)fileInfo{
    ZXLFileInfoModel *tempFileInfo = [_uploadInfo valueForKey:fileInfo.identifier];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_uploadInfo setValue:tempFileInfo forKey:tempFileInfo.identifier];
        //文件开始上传的时候先删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.identifier];
    }else{
        tempFileInfo.progress = fileInfo.progress;
        tempFileInfo.progressType = ZXLFileUploadProgressUpload;
    }
}

-(ZXLFileInfoModel *)checkComprssSuccessFileInfo:(NSString *)identifier{
    if (!ISNSStringValid(identifier))  return nil;
    
    ZXLFileInfoModel *fileInfo = [_comprssResultInfo valueForKey:identifier];
    if (fileInfo) {
        NSString * videoName = [fileInfo uploadKey];
        NSString * comprssURL = FILE_Video_PATH(videoName);
        //文件存在返回结果
        if (fileInfo.comprssSuccess && [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
            return fileInfo;
        }else
        {
            [_comprssResultInfo removeObjectForKey:identifier];
            //文件不存在删除保存过的文件信息
            NSMutableDictionary *tempcomprssInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentComprssInfo];
            [tempcomprssInfo removeObjectForKey:fileInfo.identifier];
            [ZXLDocumentUtils setDictionaryByListName:tempcomprssInfo fileName:ZXLDocumentComprssInfo];
        }
    }
    return nil;
}

-(ZXLFileInfoModel *)checkUploadSuccessFileInfo:(NSString *)identifier{
    if (!ISNSStringValid(identifier))  return nil;
    
    ZXLFileInfoModel *fileInfo = [_uploadResultInfo valueForKey:identifier];
    if (fileInfo) {
        if (fileInfo.progressType == ZXLFileUploadProgressUploadEnd && fileInfo.uploadResult == ZXLFileUploadSuccess) {
            return fileInfo;
        }else
        {
            [_uploadResultInfo removeObjectForKey:identifier];
            //删除保存过但是错误的文件信息
            NSMutableDictionary * tmpUploadInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadResultInfo];
            [tmpUploadInfo removeObjectForKey:identifier];
            [ZXLDocumentUtils setDictionaryByListName:tmpUploadInfo fileName:ZXLDocumentUploadResultInfo];
        }
    }
    return nil;
}

/**
 检查文件是否正在压缩
 
 @param identifier 文件identifier唯一值
 @return 压缩中的文件信息
 */
-(ZXLFileInfoModel *)checkComprssProgressFileInfo:(NSString *)identifier{
    if (!ISNSStringValid(identifier))  return nil;
    
    return [_comprssInfo valueForKey:identifier];
}

/**
 检查文件是否正在上传
 
 @param identifier 文件identifier唯一值
 @return 上传中的文件信息
 */
-(ZXLFileInfoModel *)checkUploadProgressFileInfo:(NSString *)identifier{
    if (!ISNSStringValid(identifier))  return nil;
    
    return [_uploadInfo valueForKey:identifier];
}


-(void)addFileAVAssetExportSession:(AVAssetExportSession *)session with:(NSString *)identifier{
    if (session && ISNSStringValid(identifier)) {
        [_assetSessionDict setValue:session forKey:identifier];
    }
}

-(void)removeFileAVAssetExportSession:(NSString *)identifier{
    if (ISNSStringValid(identifier)) {
        AVAssetExportSession *session = [_assetSessionDict objectForKey:identifier];
        if (session) {
            [session cancelExport];
            [_assetSessionDict removeObjectForKey:identifier];
        }
        
        ZXLFileInfoModel *fileInfo = [_comprssInfo valueForKey:identifier];
        if (fileInfo) {
            //删除压缩过没有压缩完的视频,且没有成功记录的视频
            if (![_comprssResultInfo objectForKey:identifier]) {
                NSString * videoName = [fileInfo uploadKey];
                NSString *strComprssUrl = FILE_Video_PATH(videoName);
                if ([[NSFileManager defaultManager] fileExistsAtPath:strComprssUrl]) {
                    BOOL bRemove = [[NSFileManager defaultManager] removeItemAtPath:strComprssUrl error:nil];
                    if (bRemove) {
                        //                 NSLog(@"删除没有压缩完成的视频%@",strComprssUrl);
                    }
                }
            }
            
            [_comprssInfo removeObjectForKey:identifier];
        }
    }
}

-(AVAssetExportSession *)getAVAssetExportSession:(NSString *)identifier{
    if (ISNSStringValid(identifier)) {
        return [_assetSessionDict objectForKey:identifier];
    }
    return nil;
}

/**
 添加文件上传Request
 
 @param request Request
 */
-(void)addUploadRequest:(id)request with:(NSString *)identifier{
    if (request && ISNSStringValid(identifier)) {
        [_sessionRequestDict setValue:request forKey:identifier];
    }
}

/**
 删除文件上传Request
 
 @param identifier 文件identifier
 */
-(void)removeUploadRequest:(NSString *)identifier{
    if (ISNSStringValid(identifier)) {
        id request = [_sessionRequestDict valueForKey:identifier];
        if (request) {
            //注意:此处停止上传请求
//          [request cancel];
            
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
    //删除正在压缩记录
    [self removeFileAVAssetExportSession:identifier];
    
    //删除上传请求
    [self removeUploadRequest:identifier];
    
    //删除出错历史
    [_uploadErrorInfo removeObjectForKey:identifier];
    
}


@end
