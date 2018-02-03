//
//  ZXLNetworkManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/3.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLNetworkManager.h"
#import "ZXLNetworkReachabilityManager.h"

@implementation ZXLNetworkManager
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLNetworkManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLNetworkManager alloc] init];
    });
    return _sharedObject;
}

- (instancetype)init{
    if (self = [super init]) {
        
        ZXLNetworkReachabilityManager *mangerNet = [ZXLNetworkReachabilityManager sharedManager];
        [mangerNet startMonitoring];
        
        [mangerNet setReachabilityStatusChangeBlock:^(ZXLNetworkReachabilityStatus status) {
            
            
//            BOOL bNetworkStatusChange = YES;
//            if ((system_networkstatus > ZXLNetworkReachabilityStatusNotReachable && status > ZXLNetworkReachabilityStatusNotReachable)||
//                (system_networkstatus <= ZXLNetworkReachabilityStatusNotReachable && status <= ZXLNetworkReachabilityStatusNotReachable)) {
//                bNetworkStatusChange = NO;
//            }
//
//            system_networkstatus = status;
            
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"JLBNetWorkStatusChange" object:bNetworkStatusChange?@"1":@"0"];
        
        }];
    }
    return self;
}

@end
