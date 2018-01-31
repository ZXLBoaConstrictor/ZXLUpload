//
//  ZXLUploadFileResultCenter.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadFileResultCenter.h"
#import "ZXLFileInfoModel.h"
#import "ZXLUploadTaskCenter.h"

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
+(ZXLUploadFileResultCenter*)shareUploadResultCenter
{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadFileResultCenter * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadFileResultCenter alloc] initLoadLocalUploadInfo];
    });
    return _sharedObject;
}

- (instancetype)initLoadLocalUploadInfo
{
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
         }
     }
    return self;
}

-(void)clearAllUploadFileInfo
{
    [_uploadResultInfo removeAllObjects];
    [_comprssResultInfo removeAllObjects];
    [_uploadInfo removeAllObjects];
    [_comprssInfo removeAllObjects];
    [_assetSessionDict removeAllObjects];
    [_uploadErrorInfo removeAllObjects];
    [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentUploadResultInfo];
    [ZXLDocumentUtils setDictionaryByListName:[NSMutableDictionary dictionary] fileName:ZXLDocumentComprssInfo];
}


-(void)saveComprssSuccess:(ZXLFileInfoModel *)fileInfo
{
    if (!fileInfo || fileInfo.fileType != ZXLFileTypeVideo) return;
    
    NSString * videoName = [fileInfo uploadKey];
    NSString * comprssURL = FILE_Video_PATH(videoName);
    if (![self checkComprssSuccessFileInfo:fileInfo.uuid] && //检查此文件是否保存过
        fileInfo.comprssSuccess &&  //检查压缩成功后的地址和压缩后的文件是否存在
        [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
        
        //压缩成功后把压缩过程存的文件信息删除
        [self removeFileAVAssetExportSession:fileInfo.uuid];
        
        NSMutableDictionary *tempcomprssInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentComprssInfo];
        [tempcomprssInfo setValue:[fileInfo keyValues] forKey:fileInfo.uuid];
        [ZXLDocumentUtils setDictionaryByListName:tempcomprssInfo fileName:ZXLDocumentComprssInfo];
        
        ZXLFileInfoModel * tempFileInfo = [ZXLFileInfoModel dictionary:[tempcomprssInfo valueForKey:fileInfo.uuid]];
        //存储成功记录
        [_comprssResultInfo setValue:tempFileInfo forKey:fileInfo.uuid];
    }
}

-(void)saveUploadSuccess:(ZXLFileInfoModel *)fileInfo
{
    if (!fileInfo) return;
    
    //检查此文件是否保存过和文件是否上传成功
    if (![self checkUploadSuccessFileInfo:fileInfo.uuid]&&
        fileInfo.progressType == ZXLFileUploadProgressUploadEnd &&
        fileInfo.uploadResult == ZXLFileUploadSuccess) {
        //文件开始压缩的时候先删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.uuid];
        
        //上传成功后把上传过程存的文件信息删除
        [_uploadInfo removeObjectForKey:fileInfo.uuid];
        
        //删除上传任务
        [self removeUploadRequest:fileInfo.uuid];
        
        NSMutableDictionary * tmpUploadInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadResultInfo];
        [tmpUploadInfo setValue:[fileInfo keyValues] forKey:fileInfo.uuid];
        [ZXLDocumentUtils setDictionaryByListName:tmpUploadInfo fileName:ZXLDocumentUploadResultInfo];
        
        ZXLFileInfoModel * tempFileInfo = [ZXLFileInfoModel dictionary:[tmpUploadInfo valueForKey:fileInfo.uuid]];
        //存储成功记录
        [_uploadResultInfo setValue:tempFileInfo forKey:fileInfo.uuid];
        
        [[ZXLUploadTaskCenter shareUploadTask] changeFileUploadResult:fileInfo.uuid type:ZXLFileUploadSuccess];
    }
}

-(void)saveUploadError:(ZXLFileInfoModel *)fileInfo
{
    if (!fileInfo) return;
    
    ZXLFileInfoModel *tempFileInfo = [_uploadErrorInfo valueForKey:fileInfo.uuid];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_uploadErrorInfo setValue:tempFileInfo forKey:tempFileInfo.uuid];
        
        //删除上传任务
        [self removeUploadRequest:fileInfo.uuid];
    }
}

/**
 保存文件压缩过程信息
 
 @param fileInfo 文件信息
 */
-(void)saveComprssProgress:(ZXLFileInfoModel *)fileInfo ExportSession:(AVAssetExportSession *)session
{
    if (!fileInfo || !session ||fileInfo.fileType != ZXLFileTypeVideo) return;
    
    ZXLFileInfoModel *tempFileInfo = [_comprssInfo valueForKey:fileInfo.uuid];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_comprssInfo setValue:tempFileInfo forKey:tempFileInfo.uuid];
        
        //文件开始压缩的时候先删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.uuid];
        //保存session
        [self addFileAVAssetExportSession:session with:fileInfo.uuid];
        
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
-(void)saveUploadProgress:(ZXLFileInfoModel *)fileInfo
{
    ZXLFileInfoModel *tempFileInfo = [_uploadInfo valueForKey:fileInfo.uuid];
    if (!tempFileInfo) {
        tempFileInfo = [ZXLFileInfoModel dictionary:[fileInfo keyValues]];
        [_uploadInfo setValue:tempFileInfo forKey:tempFileInfo.uuid];
        //文件开始上传的时候先删除出错历史
        [_uploadErrorInfo removeObjectForKey:fileInfo.uuid];
    }else
    {
        tempFileInfo.progress = fileInfo.progress;
        tempFileInfo.progressType = ZXLFileUploadProgressUpload;
    }
}

-(ZXLFileInfoModel *)checkComprssSuccessFileInfo:(NSString *)uuidStr
{
    if (!ISNSStringValid(uuidStr))  return nil;
    
    ZXLFileInfoModel *fileInfo = [_comprssResultInfo valueForKey:uuidStr];
    if (fileInfo) {
        NSString * videoName = [fileInfo uploadKey];
        NSString * comprssURL = FILE_Video_PATH(videoName);
        //文件存在返回结果
        if (fileInfo.comprssSuccess && [[NSFileManager defaultManager] fileExistsAtPath:comprssURL]) {
            return fileInfo;
        }else
        {
            [_comprssResultInfo removeObjectForKey:uuidStr];
            //文件不存在删除保存过的文件信息
            NSMutableDictionary *tempcomprssInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentComprssInfo];
            [tempcomprssInfo removeObjectForKey:fileInfo.uuid];
            [ZXLDocumentUtils setDictionaryByListName:tempcomprssInfo fileName:ZXLDocumentComprssInfo];
        }
    }
    return nil;
}

-(ZXLFileInfoModel *)checkUploadSuccessFileInfo:(NSString *)uuidStr
{
    if (!ISNSStringValid(uuidStr))  return nil;
    
    ZXLFileInfoModel *fileInfo = [_uploadResultInfo valueForKey:uuidStr];
    if (fileInfo) {
        if (fileInfo.progressType == ZXLFileUploadProgressUploadEnd && fileInfo.uploadResult == ZXLFileUploadSuccess) {
            return fileInfo;
        }else
        {
            [_uploadResultInfo removeObjectForKey:uuidStr];
            //删除保存过但是错误的文件信息
            NSMutableDictionary * tmpUploadInfo = [ZXLDocumentUtils dictionaryByListName:ZXLDocumentUploadResultInfo];
            [tmpUploadInfo removeObjectForKey:uuidStr];
            [ZXLDocumentUtils setDictionaryByListName:tmpUploadInfo fileName:ZXLDocumentUploadResultInfo];
        }
    }
    return nil;
}

/**
 检查文件是否正在压缩
 
 @param uuidStr 文件uuid唯一值
 @return 压缩中的文件信息
 */
-(ZXLFileInfoModel *)checkComprssProgressFileInfo:(NSString *)uuidStr
{
    if (!ISNSStringValid(uuidStr))  return nil;
    
    return [_comprssInfo valueForKey:uuidStr];
}

/**
 检查文件是否正在上传
 
 @param uuidStr 文件uuid唯一值
 @return 上传中的文件信息
 */
-(ZXLFileInfoModel *)checkUploadProgressFileInfo:(NSString *)uuidStr
{
    if (!ISNSStringValid(uuidStr))  return nil;
    
    return [_uploadInfo valueForKey:uuidStr];
}


-(void)addFileAVAssetExportSession:(AVAssetExportSession *)session with:(NSString *)uuidStr
{
    if (session && ISNSStringValid(uuidStr)) {
        [_assetSessionDict setValue:session forKey:uuidStr];
    }
}

-(void)removeFileAVAssetExportSession:(NSString *)uuidStr
{
    if (ISNSStringValid(uuidStr)) {
        AVAssetExportSession *session = [_assetSessionDict objectForKey:uuidStr];
        if (session) {
            [session cancelExport];
            [_assetSessionDict removeObjectForKey:uuidStr];
            [_comprssInfo removeObjectForKey:uuidStr];
        }
    }
}

-(AVAssetExportSession *)getAVAssetExportSession:(NSString *)uuidStr
{
    if (ISNSStringValid(uuidStr)) {
        return [_assetSessionDict objectForKey:uuidStr];
    }
    return nil;
}

/**
 添加文件上传Request
 
 @param request Request
 */
-(void)addUploadRequest:(id)request with:(NSString *)uuidStr
{
    if (request && ISNSStringValid(uuidStr)) {
        [_sessionRequestDict setValue:request forKey:uuidStr];
    }
}

/**
 删除文件上传OSSRequest
 
 @param uuidStr 文件uuid
 */
-(void)removeUploadRequest:(NSString *)uuidStr
{
    if (ISNSStringValid(uuidStr)) {
        id request = [_sessionRequestDict valueForKey:uuidStr];
        if (request) {
            //注意:此处停止上传请求
//          [request cancel];
            
            [_sessionRequestDict removeObjectForKey:uuidStr];
        }
        //删除正在上传记录
        [_uploadInfo removeObjectForKey:uuidStr];
    }
}

/**
 删除此文件在上传中留下的不成功的所有信息
 
 @param uuidStr 文件uuid
 */
-(void)removeFileInfoUpload:(NSString *)uuidStr
{
    //删除正在压缩记录
    [self removeFileAVAssetExportSession:uuidStr];
    
    //删除上传请求
    [self removeUploadRequest:uuidStr];
    
    //删除出错历史
    [_uploadErrorInfo removeObjectForKey:uuidStr];
    
}


@end
