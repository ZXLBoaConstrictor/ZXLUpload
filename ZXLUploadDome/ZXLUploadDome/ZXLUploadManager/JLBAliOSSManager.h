//
//  JLBAliOSSManager.h
//  Compass
//
//  Created by 张小龙 on 2018/5/11.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OSSRequest;
@class OSSTask;

@interface JLBAliOSSManager : NSObject
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
@end
