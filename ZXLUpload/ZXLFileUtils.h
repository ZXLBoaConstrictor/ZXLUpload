//
//  ZXLFileUtils.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZXLFileType);

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

+(UIImage *)localVideoThumbnail:(NSString *)path;

+(NSString *)base64EncodedString:(NSString *)string;

/**
 音频文件和视频文件的时长

 @param path 文件地址
 @return 时长
 */
+(NSInteger)fileCMTime:(NSString *)path;
@end

@interface UIImage (ZXLBundle)

+ (UIImage *)imageNamedFromZXLBundle:(NSString *)name;

-(UIImage*)scaleByFactor:(float)scaleFactor;
@end
