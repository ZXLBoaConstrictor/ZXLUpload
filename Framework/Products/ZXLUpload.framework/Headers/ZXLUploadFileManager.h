//
//  ZXLUploadFileManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ZXLFileInfoModel;
typedef NS_ENUM(NSUInteger, ZXLFileUploadType);

typedef void (^ZXLUploadFileResponseCallback)(ZXLFileUploadType nResult,NSString *resultURL);

typedef void (^ZXLUploadFileProgressCallback)(float progressPercent);

@interface ZXLUploadFileManager : NSObject
+ (instancetype)manager;

/**
 上传任务专用上传 （检测过文件压缩、文件上传）

 @param fileInfo 文件信息
 @param progress 上传进度
 @param complete 上传结果
 */
- (void)taskUploadFile:(ZXLFileInfoModel *)fileInfo
             progress:(ZXLUploadFileProgressCallback)progress
               complete:(ZXLUploadFileResponseCallback)complete;

/**
 单个文件上传 （本来此处考虑，同文件多个地方上传情况，先不考虑。场景：上传任务中有文件正在上传，单个文件又上传）

 @param fileInfo 文件信息
 @param progress 上传进度
 @param complete 上传结果
 */
- (void)uploadFile:(ZXLFileInfoModel *)fileInfo
          progress:(ZXLUploadFileProgressCallback)progress
          complete:(ZXLUploadFileResponseCallback)complete;
@end
