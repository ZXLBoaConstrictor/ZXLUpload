//
//  ZXLTaskInfoModel.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLFileInfoModel.h"

@interface ZXLTaskInfoModel : NSObject
@property (nonatomic,copy)NSString *identifier; //任务标识符（确保标识符的唯一性）

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
-(ZXLFileUploadType)uploadTaskType;


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
 清空上传任务进度
 */
-(void)clearProgress;

@end
