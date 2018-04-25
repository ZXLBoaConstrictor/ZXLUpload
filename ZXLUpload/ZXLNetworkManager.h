//
//  ZXLNetworkManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/3.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface ZXLNetworkManager : NSObject
+ (instancetype)manager;

/**
 判断App 是否有网络

 @return 网络判断
 */
+(BOOL)appHaveNetwork;
@end
