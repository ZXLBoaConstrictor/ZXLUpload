//
//  ZXLNetworkManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/3.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, ZXLNetworkReachabilityStatus);

@interface ZXLNetworkManager : NSObject
@property(nonatomic,assign)ZXLNetworkReachabilityStatus networkstatus;

/**
 判断网络状态从有网到无网的变化，或者从无网到有网的变化
 */
@property(nonatomic,assign)BOOL networkStatusChange;

+ (instancetype)manager;

/**
 判断App 是否有网络

 @return 网络判断
 */
+(BOOL)appHaveNetwork;
@end
