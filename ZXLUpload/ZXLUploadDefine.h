//
//  ZXLUploadDefine.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

//文件前缀
#define ZXLFilePrefixion @"jlboss"

//服务器域名
#define ZXLFileServerAddress @""

//NEW 对象
#define NewObject(object) [[object alloc]init];

//字符串空判断
#define ISNSStringValid(string) (string != NULL && [string length] > 0)

//字典空判断
#define ISDictionaryValid(dictionary) (dictionary != NULL && [dictionary count] > 0)

/**
 文件类型（目前先支持 图片和视频）
 - ZXLFileTypeFile: 文件
 - ZXLFileTypeImage: 图片
 - ZXLFileTypeVideo: 视频
 - ZXLFileTypeVoice: 语音
 */
typedef NS_ENUM(NSUInteger, ZXLFileType){
    ZXLFileTypeFile,
    ZXLFileTypeImage,
    ZXLFileTypeVideo,
    ZXLFileTypeVoice
} ;

typedef NS_ENUM(NSUInteger, ZXLFileFromType){
    ZXLFileFromTakePhoto,//拍摄（目前拍摄的支持视频格式）
    ZXLFileFromLoacl//本地
} ;

/**
 文件上传结果
 - ZXLFileUploadloading: 上传中
 - ZXLFileUploadSuccess: 上传成功
 - ZXLFileUploadFileError: 上传文件失败
 - ZXLFileUploadError: 上传失败
 */
typedef NS_ENUM(NSUInteger, ZXLFileUploadType){
    ZXLFileUploadloading,
    ZXLFileUploadSuccess,
    ZXLFileUploadFileError,
    ZXLFileUploadError
};


/**
 文件上传过程状态
 
 - ZXLFileUploadProgressStartUpload: 准备开始上传
 - ZXLFileUploadProgressTranscoding: 压缩中
 - ZXLFileUploadProgressUpload: 上传中
 - ZXLFileUploadProgressUploadEnd: 上传结束
 */
typedef NS_ENUM(NSUInteger, ZXLFileUploadProgressType){
    ZXLFileUploadProgressStartUpload,
    ZXLFileUploadProgressTranscoding,
    ZXLFileUploadProgressUpload,
    ZXLFileUploadProgressUploadEnd
};

/**
 上传任务状态
 
 - ZXLUploadTaskPrepareForUpload: 任务准备上传
 - ZXLUploadTaskTranscoding: 上传任务中文件压缩中
 - ZXLUploadTaskLoading: 文件上传中
 - ZXLUploadTaskSuccess: 任务成功
 - ZXLUploadTaskError: 任务失败
 */
typedef NS_ENUM(NSUInteger, ZXLUploadTaskType){
    ZXLUploadTaskPrepareForUpload,
    ZXLUploadTaskTranscoding,
    ZXLUploadTaskLoading,
    ZXLUploadTaskSuccess,
    ZXLUploadTaskError
};
