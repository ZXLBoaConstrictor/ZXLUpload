//
//  ZXLUploadTaskManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/2.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZXLFileInfoModel;
@class ZXLTaskInfoModel;
@protocol ZXLUploadTaskResponeseDelegate;
typedef NS_OPTIONS(NSInteger, ZXLRestUploadTaskType);
typedef NS_ENUM(NSUInteger, ZXLFileUploadType);

/**
 文件上传任务进度

 @param progressPercent 进度百分比
 */
typedef void (^ZXLUploadTaskProgressCallback)(float progressPercent);

/**
文件上传任务压缩进度

 @param compressPercent 压缩进度百分比
 */
typedef void (^ZXLUploadTaskCompressCallback)(float compressPercent);

/**
 文件上传任务结果block回调
 
 @param taskInfo 上传结果文件信息
 */
typedef void (^ZXLUploadTaskResponseCallback)(ZXLTaskInfoModel *taskInfo);

@interface ZXLUploadTaskManager : NSObject
+ (instancetype)manager;

/**
 清除所有上传任务,同时也清除本地缓存数据
 （注：如果有任务正在上传则清除失败）
 */
-(BOOL)clearUploadTask;

/**
 是否有上传任务正在上传

 @return 查询结果
 */
-(BOOL)haveUploadTaskLoading;

/**
 网络环境变化
 */
-(void)refreshNetWorkStatus;

/**
 app 重启后重新开始上传存储的本地任务
 (注：此函数重传 ZXLRestUploadTaskProcess 标志的 ZXLTaskInfoModel)
 */
-(void)restUploadTaskReStartProcess;

/**
 添加上传任务结果回调

 @param delegate 代理
 @param identifier 任务唯一值
 */
- (void)addUploadTaskEndResponeseDelegate:(id<ZXLUploadTaskResponeseDelegate>)delegate forIdentifier:(NSString *)identifier;

/**
 删除上传任务(建议在界面释放函数中释放identifier)

 @param identifier 任务唯一值
 */
- (void)removeTaskForIdentifier:(NSString *)identifier;


- (void)startUploadWithUnifiedResponeseForIdentifier:(NSString *)identifier;
/**
 任务启动上传
(注：此函数上传用于统一处理返回，用此函数必须扩展使用ZXLUploadUnifiedResponese 并实现 ZXLUploadTaskResponeseDelegate)
 @param identifier 任务唯一值
 @param resetUploadType 重传类型
 */
- (void)startUploadWithUnifiedResponeseForIdentifier:(NSString *)identifier resetUpload:(ZXLRestUploadTaskType)resetUploadType;

/**
 任务启动上传
 （注: 此函数上传返回结果为block形式,返回结果如果添加了delegate，则返回结果任然会以block形式返回,
    断网、杀进程不会重传）
 @param identifier 任务唯一值
 @param compress 压缩进度
 @param progress 上传进度
 @param complete 上传结果
 */
- (void)startUploadForIdentifier:(NSString *)identifier
                        compress:(ZXLUploadTaskCompressCallback)compress
                        progress:(ZXLUploadTaskProgressCallback)progress
                        complete:(ZXLUploadTaskResponseCallback)complete;


/**
 任务启动上传
 （注: 此函数上传返回结果为deelegate代理形式,所以要先添加delegate（addUploadTaskEndResponeseDelegate），所以identifier不使用时记得释放（removeTaskForIdentifier）。
 断网、杀进程不会重传）
 @param identifier 任务唯一值
 */
- (void)startUploadForIdentifier:(NSString *)identifier;

/**
 获取任务信息
 
 @param identifier 任务唯一标识
 @return 上传任务信息
 */
- (ZXLTaskInfoModel *)uploadTaskInfoForIdentifier:(NSString *)identifier;

/**
 设置所有任务中，此文件上传结果
 
 @param fileIdentifier 文件唯一标识
 @param result 上传结果
 */
- (void)setFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result;

/**
 判断此文件上传过程信息能不能删除
 
 @param taskIdentifier 父任务唯一标识
 @param fileIdentifier 文件唯一标识
 @return 是否可以删除
 */
- (BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier;


/**
 任务中心对文件 增、删操作（注：只有任务未开始上传或者上传失败的情况下才能增、删）

 @param fileInfo 文件信息
 @param identifier 任务唯一标识
 */
- (void)addUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier;

- (void)addUploadFiles:(NSMutableArray<ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier;

- (void)insertUploadFile:(ZXLFileInfoModel *)fileInfo atIndex:(NSUInteger)index forIdentifier:(NSString *)identifier;

- (void)insertUploadFilesFirst:(NSMutableArray <ZXLFileInfoModel *> *)fileInfos forIdentifier:(NSString *)identifier;

- (void)replaceUploadFileAtIndex:(NSUInteger)index withUploadFile:(ZXLFileInfoModel *)fileInfo forIdentifier:(NSString *)identifier;

- (void)removeUploadFileAtIndex:(NSUInteger)index forIdentifier:(NSString *)identifier;

- (void)removeUploadFile:(NSString *)fileIdentifier forIdentifier:(NSString *)identifier;

- (void)removeAllUploadFilesForIdentifier:(NSString *)identifier;

@end
