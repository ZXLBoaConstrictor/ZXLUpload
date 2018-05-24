//
//  JLBUploadTaskModel.h
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JLBUploadTaskModel : NSObject
@property (nonatomic,copy)NSString*                         taskTid;//是否显示在进度条中
@property (nonatomic,copy)NSString*                         taskName;//任务名称
@property (nonatomic,copy)NSString*                         taskImageURL;//是否显示在进度条中
@property (nonatomic,copy)NSString*                         content;//上传任务信息
@property (nonatomic,copy)NSString*                         uploadIdentifier;//上传任务唯一标示

+ (instancetype)dictionary:(NSDictionary *)dictionary;

/**简单实现公司业务上传任务信息中的上传任务中的状态方便调用*/

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
@end
