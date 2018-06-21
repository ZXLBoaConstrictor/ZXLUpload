//
//  ZXLFileInfoModel.h
//  ZXLUpload
//  文件信息
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
typedef NS_ENUM(NSUInteger, ZXLFileUploadProgressType);
typedef NS_ENUM(NSUInteger, ZXLFileUploadType);
typedef NS_ENUM(NSUInteger, ZXLFileType);

@interface ZXLFileInfoModel : NSObject

/**
 文件信息的唯一值
 1.相册文件:用文件的assetLocalIdentifier的base64(base64EncodedString)作为identifier
 2.路径文件:用文件的信息的MD5值（fileMd5HashCreateWithPath）作为identifier
 */
@property (nonatomic,copy)NSString  *                      identifier;

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
@property (nonatomic,copy)NSString  *                      superTaskIdentifier;//文件所在上传任务id标识（空则此次文件上传信息不在上传任务中）

@property (nonatomic,assign)float                          progress; //文件上传进度
@property (nonatomic,assign)BOOL                           comprssSuccess;//压缩成功（针对视频文件）
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
  以UIImage 类型 创建上传文件信息model
 （注：此函数主要针对从 UIImagePickerController 拍照出来的照片选择原照片照片太大，而且上传后打开造成内存急速上涨问题）
 
 @param image 要上传的图片iamge
 @return 构建的上传文件信息model
 */
-(instancetype)initWithUIImagePickerControllerImage:(UIImage *)image;

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
+(NSMutableArray<ZXLFileInfoModel *> *)initWithAssets:(NSArray <PHAsset *> *)assets;

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
 相册图片进行获取

 @param completed 获取结果
 */
-(void)albumImageRequest:(void (^)(BOOL bResult ))completed;

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
 设置当前文件状态基于另一个相同文件信息

 @param sameFileInfo 相同文件信息
 */
-(void)setUploadStateWithTheSame:(ZXLFileInfoModel *)sameFileInfo;

/**
 重置文件信息-（在上传失败的时候用）
 */
-(void)resetFileInfo;

/**
 获取文件缩略图

 @param completed 返回缩略图
 */
-(void)getThumbnail:(void (^)(UIImage * image))completed;

/**
 上传任务遇到网络错误的时候
 */
- (void)networkError;


@end
