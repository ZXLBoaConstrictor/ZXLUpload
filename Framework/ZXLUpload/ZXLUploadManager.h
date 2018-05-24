//
//  ZXLUploadManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/5/11.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZXLUploadManager : NSObject
@property (nonatomic,copy)NSString * fileServerAddress;
+(instancetype)manager;

/**
 文件上传
 
 @param objectKey 文件唯一Key
 @param filePath 文件本地地址
 @param progress 上传进度
 @param complete 文件上传结果
 */
-(id)uploadFile:(NSString *)objectKey
  localFilePath:(NSString *)filePath
       progress:(void (^)(float percent))progress
       complete:(void (^)(BOOL result))complete;
@end
