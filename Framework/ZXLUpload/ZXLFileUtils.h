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


/**
 根据文件路径返回文件类型（简单做了音频MP3、视频MP4、图片的判断）

 @param filePath 文件路径
 @return 文件类型
 */
+(ZXLFileType)fileTypeByURL:(NSString *)filePath;

+(NSInteger)fileSizeByPath:(NSString *)localURL;

+(NSString *)fileMd5HashCreateWithPath:(NSString *)filePath;

+(NSString *)fileNameWithidentifier:(NSString *)identifier fileExtension:(NSString *)extension;

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

@interface NSDictionary (ZXLJSONString)
- (NSString*)JSONString;
@end

@interface NSArray (ZXLJSONString)
- (NSString*)JSONString;
@end

@interface NSString (ZXLJSONString)
- (NSArray *)array;
- (NSDictionary *)dictionary;
+ (NSString *)ZXLUploadViewCreateTimeIdentifier;
@end

