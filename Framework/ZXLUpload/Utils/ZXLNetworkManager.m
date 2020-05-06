//
//  ZXLNetworkManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/2/3.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLNetworkManager.h"
#import "ZXLReachability.h"
#import "ZXLUploadDefine.h"
@interface ZXLNetworkManager()
@property(nonatomic,assign)BOOL haveNetwork;
@property (nonatomic) ZXLReachability *reachability;
@end

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:ZXLReachabilityChangedNotification object:nil];
        self.reachability = [ZXLReachability reachabilityWithHostName:@"www.apple.com"];
        self.haveNetwork = [self.reachability isReachable];
        [self.reachability startNotifier];
    }
    return self;
}

- (void)reachabilityChanged:(NSNotification *)note{
    ZXLReachability* curReach = [note object];
    BOOL isReachable = [curReach isReachable];
    if (self.haveNetwork != isReachable) {
        self.haveNetwork = isReachable;
        [[NSNotificationCenter defaultCenter] postNotificationName:ZXLNetworkReachabilityNotification object:self.haveNetwork?@"1":@"0"];
    }
}

+(BOOL)appHaveNetwork{
    BOOL bNetwork = NO;
    ZXLReachability *reach = [ZXLReachability reachabilityWithHostName:@"www.apple.com"];
    if(reach){
        bNetwork = [reach isReachable];
    }
    return bNetwork;
}
@end
