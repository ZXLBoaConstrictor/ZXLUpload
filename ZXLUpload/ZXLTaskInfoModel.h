//
//  ZXLTaskInfoModel.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZXLFileInfoModel;

@interface ZXLTaskInfoModel : NSObject
@property (nonatomic,copy)NSString *identifier;
@property (nonatomic,strong)NSMutableArray<ZXLFileInfoModel *> *   ayFileInfo;     //文件上传任务数组

@end
