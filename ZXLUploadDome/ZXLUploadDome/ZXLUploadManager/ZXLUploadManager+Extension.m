//
//  ZXLUploadManager+Extension.m
//  Compass
//
//  Created by 张小龙 on 2018/5/11.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "ZXLUploadManager+Extension.h"
#import "JLBAliOSSManager.h"

@implementation ZXLUploadManager(basePrivate)
-(NSString *)serverAddress{
    return @"https://images2.bestjlb.com/";
}

-(id)extensionUploadFile:(NSString *)objectKey
           localFilePath:(NSString *)filePath
                progress:(void (^)(float percent))progress
                complete:(void (^)(BOOL result))complete{
    return [[JLBAliOSSManager manager] uploadFile:objectKey localFilePath:filePath progress:progress result:^(OSSTask *task) {
        OSSInitMultipartUploadResult * uploadResult = task.result;
        if (complete) {
            complete(task && uploadResult && uploadResult.httpResponseCode == 200);
        }
    }];
}

@end
