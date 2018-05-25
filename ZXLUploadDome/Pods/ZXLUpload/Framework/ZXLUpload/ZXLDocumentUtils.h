//
//  ZXLDocumentUtils.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZXLFileType);

// 下载文件的总文件夹
#define BASEDocument       @"ZXLDocumentFile"

// 主目录
#define FILE_DIRECTORY             [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]

//fmdb 存储路径
#define ZXLUploadFmdbPath          [NSString stringWithFormat:@"%@/com.zxl.tool.ZXLUpload.db",FILE_DIRECTORY]

// 视频文件夹路径
#define FILE_Video_FOLDER          [NSString stringWithFormat:@"%@/%@/ZXLVideo",FILE_DIRECTORY,BASEDocument]
// 图片文件夹路径
#define FILE_Image_FOLDER          [NSString stringWithFormat:@"%@/%@/ZXLImage",FILE_DIRECTORY,BASEDocument]
// 语音文件夹路径
#define FILE_Voice_FOLDER          [NSString stringWithFormat:@"%@/%@/ZXLVoice",FILE_DIRECTORY,BASEDocument]
//其他文件路径
#define FILE_Other_FOLDER          [NSString stringWithFormat:@"%@/%@/ZXLOther",FILE_DIRECTORY,BASEDocument]

//视频路径
#define FILE_Video_PATH(name)      [NSString stringWithFormat:@"%@/%@",[ZXLDocumentUtils createFolder:FILE_Video_FOLDER],name]
//图片路径
#define FILE_Image_PATH(name)      [NSString stringWithFormat:@"%@/%@",[ZXLDocumentUtils createFolder:FILE_Image_FOLDER],name]
//语音路径
#define FILE_Voice_PATH(name)      [NSString stringWithFormat:@"%@/%@",[ZXLDocumentUtils createFolder:FILE_Voice_FOLDER],name]
//其他文件
#define FILE_Other_PATH(name)      [NSString stringWithFormat:@"%@/%@",[ZXLDocumentUtils createFolder:FILE_Other_FOLDER],name]

@interface ZXLDocumentUtils : NSObject

/**
 创建目录

 @param path 目录路径
 @return 返回创建成功的路径
 */
+ (NSString *)createFolder:(NSString *)path;

/**
 图片保存本地

 @param image 图片
 @return 保存成功后的文件路径
 */
+ (NSString *)saveImageByName:(UIImage *)image;

+ (NSString *)saveImage:(UIImage *)image name:(NSString *)fileName;

/**
 本地文件路径

 @param fileName 文件名称
 @param fileType 文件类型
 @return 文件路径
 */
+ (NSString *)localFilePath:(NSString *)fileName fileType:(ZXLFileType)fileType;


/**
 App 拍摄视频缓存路径

 @param takePhotoVideoURL 视频路径
 @return 当前拍摄的视频路径
 */
+(NSString *)takePhotoVideoURL:(NSString *)takePhotoVideoURL;

@end
