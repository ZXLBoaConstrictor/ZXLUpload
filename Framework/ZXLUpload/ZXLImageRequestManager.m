//
//  ZXLImageRequestManager.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/6/20.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLImageRequestManager.h"
#import "ZXLImageRequestOperation.h"
#import "ZXLUploadDefine.h"

#define ZXLMaxConcurrentOperationCount 5 //控制执行数量

@interface ZXLImageRequestManager ()
@property (nonatomic, strong) dispatch_queue_t addOperationSerialQueue;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation ZXLImageRequestManager
-(instancetype)init{
    if (self = [super init]) {
        self.addOperationSerialQueue = dispatch_queue_create("com.ZXLUpload.ZXLImageRequestManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = ZXLMaxConcurrentOperationCount;
        [self.operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLImageRequestManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLImageRequestManager alloc] init];
    });
    return _sharedObject;
}

+ (void)imageRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"ZXLImageRequestAsyncOperation"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

static NSThread *_compressThread = nil;
static dispatch_once_t oncePredicate;
+ (NSThread *)operationThread {
    dispatch_once(&oncePredicate, ^{
        _compressThread = [[NSThread alloc] initWithTarget:self selector:@selector(imageRequestThreadEntryPoint:) object:nil];
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
        [ZXLImageRequestManager operationThreadAttemptDealloc];
    }
}


-(void)imageRequest:(NSString *)assetLocalIdentifier
     fileIdentifier:(NSString *)fileId
           callback:(ZXLImageRequestCallback)callback{
    if (!ZXLISNSStringValid(assetLocalIdentifier) || !ZXLISNSStringValid(fileId)) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.addOperationSerialQueue, ^{
        ZXLImageRequestOperation * operation = [weakSelf isImageRequestFile:fileId];
        if (operation) {
            [operation addImageRequestCallback:callback];
        }else{
            operation = [[ZXLImageRequestOperation alloc] initWithIdentifier:assetLocalIdentifier fileIdentifier:fileId callback:callback];
            [weakSelf.operationQueue addOperation:operation];
        }
    });
}

- (ZXLImageRequestOperation *)isImageRequestFile:(NSString *)fileIdentifier {
    if (!ZXLISNSStringValid(fileIdentifier)) return nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", fileIdentifier];
    NSArray *filterResult = [self.operationQueue.operations filteredArrayUsingPredicate:predicate];
    if (filterResult.count > 0) {
        return (ZXLImageRequestOperation *)[filterResult firstObject];
    }
    return nil;
}

-(void)cancelImageRequestOperationForIdentifier:(NSString *)fileIdentifier{
    ZXLImageRequestOperation * operation = [self isImageRequestFile:fileIdentifier];
    if (operation && ![operation isCancelled]) {
        [operation cancel];
    }
}

-(void)cancelImageRequestOperations{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.operationQueue cancelAllOperations];
    });

}


@end
