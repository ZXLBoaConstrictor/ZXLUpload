//
//  ZXLAliOSSManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/11.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class OSSRequest;
@class OSSTask;

@interface ZXLAliOSSManager : NSObject

+(instancetype)manager;

/**
 阿里云普通文件上传
 
 @param objectKey 文件唯一Key
 @param filePath 文件本地地址
 @param progress 上传进度
 @param result 文件上传结果
 */
-(OSSRequest *)uploadFile:(NSString *)objectKey
            localFilePath:(NSString *)filePath
                 progress:(void (^)(float percent))progress
                   result:(void (^)(OSSTask *task))result;

/**
 阿里云大文件上传
 
 @param objectKey 文件唯一Key
 @param filePath 文件本地地址
 @param progress 上传进度
 @param result 文件上传结果
 */
-(OSSRequest *)bigFileUploadFile:(NSString *)objectKey
                   localFilePath:(NSString *)filePath
                        progress:(void (^)(float percent))progress
                          result:(void (^)(OSSTask *task))result;


/**
 图片上传
 
 @param image 图片
 @param progress 上传进度
 @param result 上传结果
 @return OSS 请求
 */
-(OSSRequest *)imageUploadFile:(UIImage *)image
                     objectKey:(NSString *)objectKey
                      progress:(void (^)(float percent))progress
                        result:(void (^)(OSSTask *task))result;


@end
