//
//  ZXLUploadTaskManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLTaskInfoModel.h"

@interface ZXLUploadTaskManager : NSObject
+ (instancetype)manager;

/**
 获取任务信息
 
 @param identifier 任务唯一标识
 @return 上传任务信息
 */
- (ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier;

- (void)addUploadTask:(ZXLTaskInfoModel *)taskInfo;

- (void)changeFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result;

/**
 判断此文件上传过程信息能不能删除
 
 @param taskIdentifier 父任务唯一标识
 @param fileIdentifier 文件唯一标识
 @return 是否可以删除
 */
- (BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier;
@end
