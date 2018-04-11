//
//  ZXLUploadUnifiedResponese.h
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLTaskInfoModel.h"

@interface ZXLUploadUnifiedResponese : NSObject<ZXLUploadTaskResponeseDelegate>
+ (instancetype)manager;
@end
