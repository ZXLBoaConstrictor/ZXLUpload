//
//  ZXLTaskInfoModel.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLFileInfoModel.h"


/**
 上传任务状态

 - ZXLUploadTaskPrepareForUpload: 任务准备上传
 - ZXLUploadTaskTranscoding: 上传任务中文件压缩中
 - ZXLUploadTaskLoading: 文件上传中
 - ZXLUploadTaskSuccess: 任务成功
 - ZXLUploadTaskError: 任务失败
 */
typedef NS_ENUM(NSUInteger, ZXLUploadTaskType){
    ZXLUploadTaskPrepareForUpload,
    ZXLUploadTaskTranscoding,
    ZXLUploadTaskLoading,
    ZXLUploadTaskSuccess,
    ZXLUploadTaskError
};

@interface ZXLTaskInfoModel : NSObject

/**
 任务标识符（确保标识符的唯一性）
 */
@property (nonatomic,copy)NSString *identifier;

/**
 重传标志（任务上传断网、进程重启等是否要重传--关系到是否保留任务数据）
 */
@property (nonatomic,assign)BOOL resetUpload;

+(instancetype)dictionary:(NSDictionary *)dictionary;

/**
 数据模型转字典
 
 @return NSMutableDictionary
 */
-(NSMutableDictionary *)keyValues;


/**
 当前任务进度
 
 @return 进度
 */
-(float)uploadProgress;


/**
 压缩进度
 
 @return 进度
 */
-(float)compressProgress;

/**
 当前上传任务状态
 
 @return 上传任务状态
 */
-(ZXLUploadTaskType)uploadTaskType;


/**
 上传文件总大小
 
 @return 文件总大小
 */
-(long long)uploadFileSize;


/**
 添加上传任务中得文件信息
 
 @param fileInfo 文件信息
 */
-(void)addFileInfo:(ZXLFileInfoModel *)fileInfo;


/**
 添加上传任务中的一组文件信息
 
 @param ayFileInfo 文件信息数组
 */
-(void)addFileInfos:(NSMutableArray<ZXLFileInfoModel *> *)ayFileInfo;

/**
 添加上传任务中的文件信息在第一位置
 
 @param fileInfo 文件信息
 */
-(void)insertObjectFirst:(ZXLFileInfoModel *)fileInfo;


/**
 添加上传任务中的一组文件信息在第一位置
 
 @param ayFileInfo 文件信息
 */
-(void)insertObjectsFirst:(NSMutableArray <ZXLFileInfoModel *> *)ayFileInfo;


/**
 删除上传文件

 @param identifier 文件identifier 标识符
 */
-(void)removeUploadFile:(NSString *)identifier;

/**
 判断此上传任务中有没有该文件

 @param identifier 文件唯一标识
 @return 检测结果
 */
-(BOOL)checkFileInTask:(NSString *)identifier;

/**
 清空上传任务进度
 */
-(void)clearProgress;

@end
