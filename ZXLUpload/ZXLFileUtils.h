//
//  ZXLFileUtils.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZXLUploadDefine.h"

@interface ZXLFileUtils : NSObject

/**
 同一存储本地文件格式

 @param fileType 文件类型
 @return 文件格式后缀
 */
+(NSString *)fileExtension:(ZXLFileType)fileType;

+(ZXLFileType)fileTypeByURL:(NSString *)filePath;

+(NSInteger)fileSizeByPath:(NSString *)localURL;

+(NSString *)fileMd5HashCreateWithPath:(NSString *)filePath;

+(NSString *)fileNameWithidentifier:(NSString *)identifier fileType:(ZXLFileType)fileType;

+(NSString *)serverAddressFileURL:(NSString *)fileKey;

/**
 图片MD5 值

 @param image 图片
 @return MD5值
 */
+(NSString *)imageMD5:(UIImage *)image;
@end
