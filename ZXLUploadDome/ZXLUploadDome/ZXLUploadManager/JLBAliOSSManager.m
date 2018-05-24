//
//  JLBAliOSSManager.m
//  Compass
//
//  Created by 张小龙 on 2018/5/11.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "JLBAliOSSManager.h"


@interface JLBAliOSSManager()
@property (nonatomic,strong)OSSClient *client;
@end

@implementation JLBAliOSSManager

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static JLBAliOSSManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[JLBAliOSSManager alloc] init];
        [_sharedObject ossInit];
    });
    return _sharedObject;
}

/**
 获取阿里上传endPoint
 
 @return endPoint
 */
-(NSString *)getEndPoint{
  
    return @"https://oss-cn-hangzhou.aliyuncs.com";
}

/**
 获取阿里上传BucketName
 
 @return BucketName
 */
-(NSString *)getBucketName{
    return @"jlbapp";
}



/**
 *    @brief    初始化获取OSSClient
 */
- (void)ossInit {
   
    id<OSSCredentialProvider> credential = [[OSSFederationCredentialProvider alloc] initWithFederationTokenGetter:^OSSFederationToken * {
        return [self getFederationToken];
    }];
    
    _client = [[OSSClient alloc] initWithEndpoint:[self getEndPoint] credentialProvider:credential];
}

- (OSSFederationToken *) getFederationToken{
    NSString *strSTSServer = @"http://10.10.10.23:8101/upload/token/get?tokenType=Ali";//公司获取阿里云token接口
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strSTSServer]];
    request.HTTPMethod = @"post";
    NSString *strToken = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIxMDA2OTgyIiwiaXNvbGF0aW9uIjoiYmVzdGpsYiIsImV4cCI6MTUyNzI0MTMxMiwidHlwZSI6IklPUyIsImF1dGhvcml0aWVzIjpbIlJPTEVfVVNFUiJdLCJqdGkiOiIyODIyZTcyYy1hZjg5LTQzYmQtYWQ0OC01MGY1YWQyZmIxNjEifQ.UElj2f3C8Y-e7wPGeZSr9344cmdH2CqHwi33Sg5DdCHVJKGoCfmh18SMt26SPSh9yGppUh8oEXMenKczGN0qUg";//公司登录后的token 公司内部获取阿里云上传token使用
    if (ZXLISNSStringValid(strToken)) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@",strToken] forHTTPHeaderField:@"Authorization"];
    }
    [request setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:@"JLBIOSVersion"];
    
    OSSTaskCompletionSource * tcs = [OSSTaskCompletionSource taskCompletionSource];
    
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLSessionTask * sessionTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        [tcs setError:error];
                                                        return;
                                                    }
                                                    
                                                    [tcs setResult:data];
                                                }];
    [sessionTask resume];
    
    // 实现这个回调需要同步返回Token，所以要waitUntilFinished
    [tcs.task waitUntilFinished];
    if (tcs.task.error) {
        return nil;
    } else {
        
        NSDictionary * object = [NSJSONSerialization JSONObjectWithData:tcs.task.result
                                                                options:kNilOptions
                                                                  error:nil];
        //根据公司接口返回数据组织后返回token
        OSSFederationToken * token = [OSSFederationToken new];
        token.tAccessKey = [[object objectForKey:@"result"] objectForKey:@"accessKeyId"];
        token.tSecretKey = [[object objectForKey:@"result"] objectForKey:@"accessKeySecret"];
        token.tToken = [[object objectForKey:@"result"] objectForKey:@"accessToken"];
        token.expirationTimeInMilliSecond = [[NSDate oss_clockSkewFixedDate] timeIntervalSince1970]*1000 + [[[object objectForKey:@"result"] objectForKey:@"durationSeconds"] integerValue] * 1000;
        return token;
    }
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
