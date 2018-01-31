//
//  ZXLUploadFileResultCenter.h
//  ZXLUpload
//  记录上传文件结果等信息 避免文件重传、重压缩操作
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class ZXLFileInfoModel;

@interface ZXLUploadFileResultCenter : NSObject
+(ZXLUploadFileResultCenter*)shareUploadResultCenter;
/**
 清空保存的所有的文件信息
 */
-(void)clearAllUploadFileInfo;

/**
 保存压缩成功的文件信息-目前只支持视频
 
 @param fileInfo 文件信息
 */
-(void)saveCompassSuccess:(ZXLFileInfoModel *)fileInfo;

/**
 保存上传成功后的文件信息
 
 @param fileInfo 文件信息
 */
-(void)saveUploadSuccess:(ZXLFileInfoModel *)fileInfo;


/**
 保存App 打开的时候文件上传出错的文件信息
 
 @param fileInfo 文件信息
 */
-(void)saveUploadError:(ZXLFileInfoModel *)fileInfo;

/**
 保存文件压缩过程信息
 
 @param fileInfo 文件信息
 */
-(void)saveCompassProgress:(ZXLFileInfoModel *)fileInfo ExportSession:(AVAssetExportSession *)session;


/**
 保存文件上传过程信息
 
 @param fileInfo 文件信息
 */
-(void)saveUploadProgress:(ZXLFileInfoModel *)fileInfo;

/**
 检查文件是否压缩成功过
 
 @param uuidStr 文件uuid唯一值
 @return 压缩过的文件信息
 */
-(ZXLFileInfoModel *)checkCompassSuccessFileInfo:(NSString *)uuidStr;

/**
 检查文件是否上传成功过
 
 @param uuidStr 文件uuid唯一值
 @return 上传成功过的文件信息
 */
-(ZXLFileInfoModel *)checkUploadSuccessFileInfo:(NSString *)uuidStr;

/**
 检查文件是否正在压缩
 
 @param uuidStr 文件uuid唯一值
 @return 压缩中的文件信息
 */
-(ZXLFileInfoModel *)checkCompassProgressFileInfo:(NSString *)uuidStr;

/**
 检查文件是否正在上传
 
 @param uuidStr 文件uuid唯一值
 @return 上传中的文件信息
 */
-(ZXLFileInfoModel *)checkUploadProgressFileInfo:(NSString *)uuidStr;

/**
 添加文件压缩进度session
 
 @param session AVAssetExportSession
 @param uuidStr 文件uuid
 */
-(void)addFileAVAssetExportSession:(AVAssetExportSession *)session with:(NSString *)uuidStr;


/**
 删除文件压缩进度session
 
 @param uuidStr 文件uuid
 */
-(void)removeFileAVAssetExportSession:(NSString *)uuidStr;


/**
 获取文件进度session
 
 @param uuidStr 文件uuid
 @return AVAssetExportSession
 */
-(AVAssetExportSession *)getAVAssetExportSession:(NSString *)uuidStr;

/**
 添加文件上传Request
 
 @param request Request
 */
-(void)addUploadRequest:(id)request with:(NSString *)uuidStr;

/**
 删除文件上传OSSRequest
 
 @param uuidStr 文件uuid
 */
-(void)removeUploadRequest:(NSString *)uuidStr;

/**
 删除此文件在上传中留下的不成功的所有信息
 
 @param uuidStr 文件uuid
 */
-(void)removeFileInfoUpload:(NSString *)uuidStr;
@end
