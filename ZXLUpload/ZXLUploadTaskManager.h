//
//  ZXLUploadTaskManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLUploadDefine.h"

@class ZXLFileInfoModel;
@class ZXLTaskInfoModel;

@protocol ZXLUploadTaskResponeseDelegate
@optional
-(void)uploadTaskResponese:(ZXLTaskInfoModel *)taskInfo;
@end


@interface ZXLUploadTaskManager : NSObject
+ (instancetype)manager;

/**
 添加上传任务结果回调

 @param delegate 代理
 @param identifier 任务唯一值
 */
- (void)addUploadTaskEndResponeseDelegate:(id<ZXLUploadTaskResponeseDelegate>)delegate forIdentifier:(NSString *)identifier;

/**
 删除上传任务(建议在上传任务执行完并且拿到执行结果后删除上传任务)

 @param identifier 任务唯一值
 */
- (void)removeTaskForIdentifier:(NSString *)identifier;

/**
 某个任务启动上传 -- 并标明此任务断网需要不需要重传

 @param identifier 任务唯一值
 @param bResetUpload 断网重传标识
 */
- (void)startUploadForIdentifier:(NSString *)identifier resetUpload:(BOOL)bResetUpload;

/**
 获取任务信息
 
 @param identifier 任务唯一标识
 @return 上传任务信息
 */
- (ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier;

/**
 设置所有任务中，此文件上传结果
 
 @param fileIdentifier 文件唯一标识
 @param result 上传结果
 */
- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result;

/**
 判断此文件上传过程信息能不能删除
 
 @param taskIdentifier 父任务唯一标识
 @param fileIdentifier 文件唯一标识
 @return 是否可以删除
 */
- (BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier;


/**
 任务中心对文件 增、删操作

 @param fileInfo 文件信息
 @param identifier 任务唯一标识
 */
- (void)addUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier;

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier;

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index forIdentifier:(NSString *)identifier;

- (void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier;

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier;

- (void)removeUploadFileAtIndex:(NSUInteger)index forIdentifier:(NSString *)identifier;

- (void)removeUploadFile:(NSString *)fileIdentifier forIdentifier:(NSString *)identifier;

- (void)removeAllUploadFilesForIdentifier:(NSString *)identifier;


-(void)testReUpload;

@end
