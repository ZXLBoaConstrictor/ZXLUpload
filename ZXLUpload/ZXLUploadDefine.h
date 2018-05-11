//
//  ZXLUploadDefine.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

//文件前缀
#define ZXLFilePrefixion @"jlboss"

//NEW 对象
#define ZXLNewObject(object) [[object alloc]init];

//字符串空判断
#define ZXLISNSStringValid(string) (string != NULL && [string length] > 0)

//字典空判断
#define ZXLISDictionaryValid(dictionary) (dictionary != NULL && [dictionary count] > 0)

//数组空判断
#define ZXLISArrayValid(array) (array != NULL && [array count] > 0)

//网络变化通知
#define ZXLNetworkReachabilityNotification @"ZXLNetworkReachabilityNotification"

//UIImagePickerController 选择的图片压缩比例
#define ZXLUIImagePickerControllerImageScale 0.4


// 日志
#ifdef DEBUG
#define ZXLUploadLog(...) NSLog(__VA_ARGS__)
#else
#define ZXLUploadLog(...)
#endif

/**
 文件类型（目前先支持 图片和视频）
 - ZXLFileTypeNoFile: 未知文件
 - ZXLFileTypeImage: 图片
 - ZXLFileTypeVoice: 语音
 - ZXLFileTypeVideo: 视频
 - ZXLFileTypeFile: 文件
 */
typedef NS_ENUM(NSUInteger, ZXLFileType){
    ZXLFileTypeNoFile,
    ZXLFileTypeImage,
    ZXLFileTypeVoice,
    ZXLFileTypeVideo,
    ZXLFileTypeFile
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


/**
 上传任务重传类型

 - ZXLRestUploadTaskNone: 不重传
 - ZXLRestUploadTaskNetwork: 断网重传
 - ZXLRestUploadTaskProcess: 杀进程也保留(App 重新打开的时候可以再调用函数控制重传)
 */
typedef NS_OPTIONS(NSInteger, ZXLRestUploadTaskType) {
    ZXLRestUploadTaskNone                    = 0,
    ZXLRestUploadTaskNetwork                 = 1<<0,
    ZXLRestUploadTaskProcess                 = 1<<1,
};
