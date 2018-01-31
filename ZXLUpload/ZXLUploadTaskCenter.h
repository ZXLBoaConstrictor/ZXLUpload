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

-(void)changeFileUploadResult:(NSString *)uuid type:(ZXLFileUploadType)result;
@end
