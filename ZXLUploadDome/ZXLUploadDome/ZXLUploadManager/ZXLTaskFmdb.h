//
//  ZXLTaskFmdb.h
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/5/4.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
@class JLBUploadTaskModel;

@interface ZXLTaskFmdb : NSObject
+(ZXLTaskFmdb*)manager;
//增
-(void)insertUploadTaskInfo:(JLBUploadTaskModel *)taskModel;
//删
-(void)deleteUploadTaskInfo:(JLBUploadTaskModel *)taskModel;
-(void)clearUploadTaskInfo;
//查
-(NSMutableArray<JLBUploadTaskModel *> *)selectAllUploadTaskInfo;
@end
