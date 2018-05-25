//
//  ZXLUploadManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/5/11.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadManager.h"

@implementation ZXLUploadManager
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadManager alloc] init];
    });
    return _sharedObject;
}

-(instancetype)init{
    if (self = [super init]) {
        self.fileServerAddress = [self getZXLUploadfileServerAddress];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(NSString *)getZXLUploadfileServerAddress{
    SEL selServerAddress = NSSelectorFromString(@"serverAddress");
    if ([self respondsToSelector:selServerAddress]) {
        return [self performSelector:selServerAddress];
    }
    return @"";
}

-(id)uploadFile:(NSString *)objectKey
  localFilePath:(NSString *)filePath
       progress:(void (^)(float percent))progress
       complete:(void (^)(BOOL result))complete{
    
    SEL selUpload = NSSelectorFromString(@"extensionUploadFile:localFilePath:progress:complete:");
    if ([self respondsToSelector:selUpload]) {
        IMP imp = [self methodForSelector:selUpload];
        id (*func)(id, SEL,id,id,id,id) = (void *)imp;
        return func(self,selUpload,objectKey,filePath,progress,complete);
    }
    return nil;
}
#pragma clang diagnostic pop
@end
