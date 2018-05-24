//
//  ZXLUploadFmdb.h
//  ZXLUpload
//  上传信息本地数据库存储代码
//  Created by 张小龙 on 2018/4/20.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZXLTaskInfoModel;
@class ZXLFileInfoModel;

@interface ZXLUploadFmdb : NSObject
+(ZXLUploadFmdb*)manager;
//增
-(void)insertUploadTaskInfo:(ZXLTaskInfoModel *)taskModel;
-(void)insertUploadSuccessFileResultInfo:(ZXLFileInfoModel *)fileModel;
-(void)insertCompressFileInfo:(ZXLFileInfoModel *)fileModel;
//删
-(void)deleteUploadTaskInfo:(ZXLTaskInfoModel *)taskModel;
-(void)deleteUploadSuccessFileResultInfo:(ZXLFileInfoModel *)fileModel;
-(void)deleteCompressFileInfo:(ZXLFileInfoModel *)fileModel;
-(void)clearUploadTaskInfo;
-(void)clearUploadSuccessFileResultInfo;
-(void)clearCompressFileInfo;

//查(全部)
-(NSMutableArray<ZXLTaskInfoModel *> *)selectAllUploadTaskInfo;
-(NSMutableArray<ZXLFileInfoModel *> *)selectAllUploadSuccessFileResultInfo;
-(NSMutableArray<ZXLFileInfoModel *> *)selectAllCompressFileInfo;
@end
