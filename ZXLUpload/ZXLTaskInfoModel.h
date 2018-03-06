//
//  ZXLTaskInfoModel.h
//  ZXLUpload
//  文件上传中的文件操作比较敏感，限制于上传状态，所以所有操作内部消化不允许外部操作
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLUploadDefine.h"

@class ZXLFileInfoModel;

@interface ZXLTaskInfoModel : NSObject

/**
 任务标识符（确保标识符的唯一性）
 */
@property (nonatomic,copy)NSString *identifier;

/**
 重传标志（任务上传断网、进程重启等是否要重传--关系到是否保留任务数据）
 */
@property (nonatomic,assign)BOOL resetUpload;

+ (instancetype)dictionary:(NSDictionary *)dictionary;

/**
 数据模型转字典
 
 @return NSMutableDictionary
 */
- (NSMutableDictionary *)keyValues;

/**
 任务开启上传
 */
- (void)startUpload;

/**
 上传文件数量

 @return 文件数量
 */
- (NSInteger)uploadFilesCount;

/**
 上传和压缩总进度

 @return 总上传进度
 */
- (float)uploadAndcompressProgress;

/**
 当前任务上传进度 -- 不包含压缩进度
 
 @return 进度
 */
- (float)uploadProgress;


/**
 压缩进度
 
 @return 进度
 */
- (float)compressProgress;

/**
 当前上传任务状态
 
 @return 上传任务状态
 */
- (ZXLUploadTaskType)uploadTaskType;


/**
 上传文件总大小
 
 @return 文件总大小
 */
- (long long)uploadFileSize;


/**
 添加上传任务中得文件信息
 
 @param fileInfo 文件信息
 */
- (void)addUploadFile:(ZXLFileInfoModel *)fileInfo;

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos;

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index;

- (void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos;

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo;

- (void)removeUploadFile:(NSString *)identifier;

- (void)removeUploadFileAtIndex:(NSUInteger)index;

- (void)removeAllUploadFiles;

- (ZXLFileInfoModel *)uploadFileAtIndex:(NSInteger)index;

- (ZXLFileInfoModel *)uploadFileForIdentifier:(NSString *)identifier;


/**
 判断此上传任务中有没有该文件

 @param identifier 文件唯一标识
 @return 检测结果
 */
- (BOOL)checkFileInTask:(NSString *)identifier;


/**
 设置任务中所有此文件上传结果

 @param fileIdentifier 文件唯一标识
 @param result 上传结果
 */
- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result;


/**
 清空上传任务进度
 */
- (void)clearProgress;

@end
