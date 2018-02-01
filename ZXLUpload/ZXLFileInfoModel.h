//
//  ZXLFileInfoModel.h
//  ZXLUpload
//  文件信息
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLVideoUtils.h"
#import "ZXLFileUtils.h"
#import "ZXLDocumentUtils.h"

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

@interface ZXLFileInfoModel : NSObject
//文件信息
@property (nonatomic,copy)NSString  *                      identifier;//唯一值

/**
 文件本地路径(非绝对路径，注意IOS在App进程重启的时候路径都会变掉)
 本地沙盒路径 -
 相册路径 -
 拍照路径 -
 */
@property (nonatomic,copy)NSString  *                      localURL;
@property (nonatomic,assign)NSInteger                      uploadSize; //文件上传大小
@property (nonatomic,assign)ZXLFileType                    fileType; //文件类型
@property (nonatomic,assign)NSInteger                      fileTime; //音频和视频时长
/**
 相册中的id由于相册中的文件每次App重启的时候都要请求相册文件，所以记录Id，也可以以此值来判断文件是否是相册文件
 上传过程:
 -id->请求相册文件保存本地(方便失败重传操作)->上传本地文件->删除本地保存文件
 */
@property (nonatomic,copy)NSString*                        assetLocalIdentifier;


//文件上传信息
@property (nonatomic,copy)NSString  *                      superTaskIdentifier;//文件所在上传任务id标识（空则此次文件上传信息不在上传任务中）
@property (nonatomic,assign)BOOL                           comprssSuccess;//压缩成功（针对视频文件）
@property (nonatomic,assign)float                          progress; //文件上传进度
@property (nonatomic,assign)ZXLFileUploadProgressType      progressType; //文件上传状态
@property (nonatomic,assign)ZXLFileUploadType              uploadResult; //上传结果

+(instancetype)dictionary:(NSDictionary *)dictionary;

/**
 数据模型转字典
 
 @return NSMutableDictionary
 */
-(NSMutableDictionary *)keyValues;

/**
 构建函数

 @param asset PHAsset 相册信息
 @return 上传文件信息model
 */
-(instancetype)initWithAsset:(PHAsset *)asset;

/**
 以UIImage 类型 创建上传文件信息model
 
 @param image 要上传的图片iamge
 @return 构建的上传文件信息model
 */
-(instancetype)initWithImage:(UIImage *)image;

/**
 以文件路径 创建上传文件信息model

 @param fileURL 文件路径
 @return 构建的上传文件信息model
 */
-(instancetype)initWithFileURL:(NSString *)fileURL;

/**
 构建函数

 @param assets PHAsset 相册信息数组
 @return 上传文件信息model
 */
+(NSMutableArray<ZXLFileInfoModel *> *)initWithAssets:(NSMutableArray <PHAsset *> *)assets;

/**
 以UIImage 类型 数组创建上传文件信息model 集合
 
 @param ayImages 图片集合
 @return 上传图片文件model 集合
 */
+(NSMutableArray<ZXLFileInfoModel *> *)initWithImages:(NSArray<UIImage *> *)ayImages;


/**
 视频文件压缩
 
 注意：非视频文件或者拍摄的文件找不到才会返回NO
 */
-(void)videoCompress:(void (^)(BOOL bResult ))completed;

/**
 本地上传路径 -- 视频文件要经过压缩才能获取
 
 @return 上传路径
 */
-(NSString *)localUploadURL;

/**
 文件上传名称 例子 ZXLFilePrefixion + identifier + fileExtension
 
 @return 文件名称
 */
-(NSString *)uploadKey;

/**
 设置文件上传成功

 */
-(void)setUploadResultSuccess;

/**
 设置文件上传失败
 
 @param uploadType 上传结果类型
 */
-(void)setUploadResultError:(ZXLFileUploadType)uploadType;


/**
 重置文件信息-（在上传失败的时候用）
 */
-(void)resetFileInfo;

/**
 清空缓存文件-（在上传成功用，清理缓存文件）
 */
-(void)fileClear;


@end
