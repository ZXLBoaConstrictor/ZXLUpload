//
//  ZXLAliOSSManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/11.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLAliOSSManager.h"
#import <AliyunOSSiOS/AliyunOSSiOS.h>


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface ZXLAliOSSManager()
@property (nonatomic,strong)OSSClient *client;
@end

@implementation ZXLAliOSSManager

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLAliOSSManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLAliOSSManager alloc] init];
        [_sharedObject ossInit];
    });
    return _sharedObject;
}

-(NSString *)getEndPoint{
    SEL selEndPoint = NSSelectorFromString(@"endPoint");
    if ([self respondsToSelector:selEndPoint]) {
        return [self performSelector:selEndPoint];
    }
    return @"";
}

-(NSString *)getBucketName{
    SEL selBucketName = NSSelectorFromString(@"endPoint");
    if ([self respondsToSelector:selBucketName]) {
        return [self performSelector:selBucketName];
    }
    return @"";
}

/**
 *    @brief    初始化获取OSSClient
 */
- (void)ossInit {

    id<OSSCredentialProvider> credential = [[OSSFederationCredentialProvider alloc] initWithFederationTokenGetter:^OSSFederationToken * {
        //获取FederationToken 外部利用扩展实现 getFederationToken
        SEL selToken = NSSelectorFromString(@"getFederationToken");
        if ([self respondsToSelector:selToken]) {
            return [self performSelector:selToken];
        }else{
            return nil;
        }
    }];
    
    _client = [[OSSClient alloc] initWithEndpoint:[self getEndPoint] credentialProvider:credential];
}

-(OSSRequest *)uploadFile:(NSString *)objectKey
            localFilePath:(NSString *)filePath
                 progress:(void (^)(float percent))progress
                   result:(void (^)(OSSTask *task))result{
    OSSResumableUploadRequest* resumableRequest = [[OSSResumableUploadRequest alloc] init];
    resumableRequest.bucketName = [self getBucketName];
    resumableRequest.objectKey = objectKey;
    resumableRequest.uploadingFileURL = [NSURL fileURLWithPath:filePath];
    resumableRequest.partSize = 256 * 1024;//256K 分片上传
    //totalBytesSent 上传量 totalBytesExpectedToSend 上传文件大小
    resumableRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        progress((CGFloat)totalBytesSent/(CGFloat)totalBytesExpectedToSend);
    };
    
    OSSInitMultipartUploadRequest * init = [[OSSInitMultipartUploadRequest alloc] init];
    init.bucketName = [self getBucketName];
    init.objectKey = objectKey;
    
    OSSTask * task = [_client multipartUploadInit:init];
    
    [task continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            OSSInitMultipartUploadResult * taskresult = task.result;
            resumableRequest.uploadId = taskresult.uploadId;
            OSSTask * resumeTask = [self->_client resumableUpload:resumableRequest];
            [resumeTask continueWithBlock:^id(OSSTask *partTask) {
                result(partTask);
                return nil;
            }];
            
            [task waitUntilFinished];
            
        } else {
            result(task);
        }
        return nil;
    }];
    
    return resumableRequest;
}

-(OSSRequest *)bigFileUploadFile:(NSString *)objectKey
                   localFilePath:(NSString *)filePath
                        progress:(void (^)(float percent))progress
                          result:(void (^)(OSSTask *task))result{
    OSSResumableUploadRequest* resumableRequest = [[OSSResumableUploadRequest alloc] init];
    resumableRequest.bucketName = [self getBucketName];
    resumableRequest.objectKey = objectKey;
    resumableRequest.uploadingFileURL = [NSURL fileURLWithPath:filePath];
    resumableRequest.partSize = 256 * 1024;//256K 分片上传
    //totalBytesSent 上传量 totalBytesExpectedToSend 上传文件大小
    resumableRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        
        progress((CGFloat)totalBytesSent/(CGFloat)totalBytesExpectedToSend);
    };
    
    OSSInitMultipartUploadRequest * init = [[OSSInitMultipartUploadRequest alloc] init];
    init.bucketName = [self getBucketName];
    init.objectKey = objectKey;
    
    OSSTask * task = [_client multipartUploadInit:init];
    
    [task continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            
            OSSInitMultipartUploadResult * taskresult = task.result;
            resumableRequest.uploadId = taskresult.uploadId;
            OSSTask * resumeTask = [self->_client resumableUpload:resumableRequest];
            [resumeTask continueWithBlock:^id(OSSTask *partTask) {
                result(partTask);
                return nil;
            }];
            
            [task waitUntilFinished];
            
        } else {
            result(task);
        }
        return nil;
    }];
    return resumableRequest;
}

-(OSSRequest *)imageUploadFile:(UIImage *)image
                     objectKey:(NSString *)objectKey
                      progress:(void (^)(float percent))progress
                        result:(void (^)(OSSTask *task))result{
    
    OSSPutObjectRequest * put = [[OSSPutObjectRequest alloc] init];
    
    // required fields
    put.bucketName = [self getBucketName];
    put.objectKey = objectKey;
    put.uploadingData = UIImageJPEGRepresentation(image, 1.0);
    
    // optional fields
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        progress(totalByteSent/totalBytesExpectedToSend);
    };
    put.contentType = @"";
    put.contentMd5 = @"";
    put.contentEncoding = @"";
    put.contentDisposition = @"";
    
    OSSTask * putTask = [_client putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        result(task);
        return nil;
    }];
    
    return put;
}
@end

#pragma clang diagnostic pop
