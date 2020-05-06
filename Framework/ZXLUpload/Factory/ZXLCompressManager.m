//
//  ZXLCompressManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLCompressManager.h"
#import "ZXLCompressOperation.h"
#import "ZXLUploadDefine.h"

#define ZXLMaxConcurrentOperationCount 3 //控制执行数量

@interface ZXLCompressManager ()
@property (nonatomic, strong) dispatch_queue_t addOperationSerialQueue;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation ZXLCompressManager
-(instancetype)init{
    if (self = [super init]) {
        self.addOperationSerialQueue = dispatch_queue_create("com.ZXLUpload.ZXLCompressManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = ZXLMaxConcurrentOperationCount;
        [self.operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLCompressManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLCompressManager alloc] init];
    });
    return _sharedObject;
}

+ (void)compressThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"ZXLCompressAsyncOperation"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}
static NSThread *_compressThread = nil;
static dispatch_once_t oncePredicate;

+ (NSThread *)operationThread {
    dispatch_once(&oncePredicate, ^{
        _compressThread = [[NSThread alloc] initWithTarget:self selector:@selector(compressThreadEntryPoint:) object:nil];
        [_compressThread start];
    });
    return _compressThread;
}

+(void)operationThreadAttemptDealloc{
    oncePredicate = 0;
    [_compressThread cancel];
    _compressThread = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object ==self.operationQueue && self.operationQueue.operationCount == 0) {
        [ZXLCompressManager operationThreadAttemptDealloc];
    }
}

-(void)videoAsset:(AVURLAsset *)asset fileIdentifier:(NSString *)fileId callback:(ZXLComprssCallback)callback{
    if (asset == nil || !ZXLISNSStringValid(fileId)) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.addOperationSerialQueue, ^{
        ZXLCompressOperation * operation = [weakSelf isCompressingFile:fileId];
        if (operation) {
            [operation addComprssCallback:callback];
        }else{
            operation = [[ZXLCompressOperation alloc] initWithVideoAsset:asset fileIdentifier:fileId callback:callback];
            [weakSelf.operationQueue addOperation:operation];
        }
    });
}

-(void)mp4VideoPHAsset:(PHAsset *)asset fileIdentifier:(NSString *)fileId callback:(ZXLComprssCallback)callback{
    if (asset == nil || !ZXLISNSStringValid(fileId)) {
        if (callback) {
            callback(@"",@"文件获取错误");
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.addOperationSerialQueue, ^{
        ZXLCompressOperation * operation = [weakSelf isCompressingFile:fileId];
        if (operation) {
            [operation addComprssCallback:callback];
        }else{
            operation = [[ZXLCompressOperation alloc] initWithMp4VideoPHAsset:asset fileIdentifier:fileId callback:callback];
            [weakSelf.operationQueue addOperation:operation];
        }
    });
}

- (ZXLCompressOperation *)isCompressingFile:(NSString *)fileIdentifier {
    if (!ZXLISNSStringValid(fileIdentifier)) return nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", fileIdentifier];
    NSArray *filterResult = [self.operationQueue.operations filteredArrayUsingPredicate:predicate];
    if (filterResult.count > 0) {
        return (ZXLCompressOperation *)[filterResult firstObject];
    }
    return nil;
}

#pragma mark - cancel
- (void)cancelCompressOperations {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (ZXLCompressOperation * operation in weakSelf.operationQueue.operations) {
            if (operation) {
                [operation failCancelCompress];
            }
        }
        [weakSelf.operationQueue cancelAllOperations];
    });
}

-(void)cancelCompressOperationForIdentifier:(NSString *)fileIdentifier{
    ZXLCompressOperation * operation = [self isCompressingFile:fileIdentifier];
    if (operation && ![operation isCancelled]) {
        [operation cancel];
    }
}

#pragma mark - check
-(BOOL)checkFileCompressing:(NSString *)fileIdentifier{
    return ([self isCompressingFile:fileIdentifier] != nil);
}

#pragma mark - compressprogress
-(float)compressProgressForIdentifier:(NSString *)fileIdentifier{
    ZXLCompressOperation * operation = [self isCompressingFile:fileIdentifier];
    if (operation) {
        return [operation compressProgress];
    }
    return 0;
}


@end
