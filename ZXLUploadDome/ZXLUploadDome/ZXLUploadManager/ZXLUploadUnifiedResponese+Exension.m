//
//  ZXLUploadUnifiedResponese+Exension.m
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "ZXLUploadUnifiedResponese+Exension.h"
#import "JLBUploadTaskModel.h"
#import "JLBAsyncUploadTaskManager.h"

@implementation ZXLUploadUnifiedResponese(ZXLPrivate)
-(void)extensionUnifiedResponese:(ZXLTaskInfoModel *)taskInfo{
    if (taskInfo && [taskInfo uploadTaskType] == ZXLUploadTaskSuccess) {
        //公司业务在文件任务上传成功后统一处理上传结果
        JLBUploadTaskModel *jlbTaskModel = [[JLBAsyncUploadTaskManager manager] getTaskInfoForUploadIdentifier:taskInfo.identifier];
        if (jlbTaskModel) {
            NSMutableArray *paramsArr = [NSMutableArray array];
            for (NSInteger i = 0;i < [taskInfo uploadFilesCount];i++) {
                ZXLFileInfoModel * fileInfo = [taskInfo uploadFileAtIndex:i];
                if (fileInfo) {
                    switch (fileInfo.fileType) {
                        case ZXLFileTypeImage:
                            [paramsArr addObject:@{@"imgUrl" : [fileInfo uploadKey], @"type" : @(fileInfo.fileType).stringValue}];
                            break;
                        case ZXLFileTypeVoice:
                            [paramsArr addObject:@{@"time" : @(fileInfo.fileTime).stringValue, @"imgUrl" : [fileInfo uploadKey], @"type" : @(fileInfo.fileType)}];
                            break;
                        case ZXLFileTypeVideo:
                            [paramsArr addObject:@{@"time" : @(fileInfo.fileTime).stringValue,@"imgUrl" : [fileInfo uploadKey], @"type" : @(fileInfo.fileType).stringValue}];
                            break;
                        default:
                            break;
                    }
                }
            }
            
            if (ZXLISArrayValid(paramsArr)) {
                [SVProgressHUD showSuccessWithStatus:@"上传成功"];
//                [baseHttpServer SendHttpData:@"jlbapp/core/taskpic/updatePicTask.shtml" NSMDict:@{@"taskTid" :  jlbTaskModel.taskTid,@"pices" : [paramsArr JSONString]} ByType:baseHttpServerAppPost success:^(NSURLSessionDataTask *task, id responseObject) {
//                    [[JLBAsyncUploadTaskManager manager] reomveUploadTask:jlbTaskModel.taskTid];
//                } failure:^(NSURLSessionDataTask *task, NSError *error) {
//                    JLBShowFailureMessage(error, @"上传失败！");
//                }];
            }
        }
    }
}
@end
