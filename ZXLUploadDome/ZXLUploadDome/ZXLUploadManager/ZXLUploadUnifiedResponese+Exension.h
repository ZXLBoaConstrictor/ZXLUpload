//
//  ZXLUploadUnifiedResponese+Exension.h
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZXLUploadUnifiedResponese(ZXLPrivate)

/**
 上传任务统一返回处理点

 @param taskInfo 上传结果
 */
-(void)extensionUnifiedResponese:(ZXLTaskInfoModel *)taskInfo;
@end
