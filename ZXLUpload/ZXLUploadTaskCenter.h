//
//  ZXLUploadTaskCenter.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLFileInfoModel.h"

@interface ZXLUploadTaskCenter : NSObject
+(instancetype)shareUploadTask;

-(void)changeFileUploadResult:(NSString *)fileIdentifier type:(ZXLFileUploadType)result;

/**
 判断此文件上传过程信息能不能删除

 @param taskIdentifier 父任务唯一标识
 @param fileIdentifier 文件唯一标识
 @return 是否可以删除
 */
-(BOOL)checkRemoveFile:(NSString *)taskIdentifier file:(NSString *)fileIdentifier;
@end
