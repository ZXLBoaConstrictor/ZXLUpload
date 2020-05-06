//
//  ZXLThumbnailManager.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2019/5/15.
//  Copyright © 2019 张小龙. All rights reserved.
//

#import "ZXLThumbnailManager.h"
#import "ZXLFileInfoModel.h"
#import "ZXLThumbnailOperation.h"
#import "ZXLUploadDefine.h"

#define ZXLMaxConcurrentOperationCount 3 //控制执行数量

@interface ZXLThumbnailManager ()
@property (nonatomic, strong) dispatch_queue_t addOperationSerialQueue;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation ZXLThumbnailManager
-(instancetype)init{
    if (self = [super init]) {
        self.addOperationSerialQueue = dispatch_queue_create("com.ZXLUpload.ZXLThumbnailManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = ZXLMaxConcurrentOperationCount;
        [self.operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLThumbnailManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLThumbnailManager alloc] init];
    });
    return _sharedObject;
}

+ (void)thumbnailThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"ZXLThumbnailAsyncOperation"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

static NSThread *_compressThread = nil;
static dispatch_once_t oncePredicate;
+ (NSThread *)operationThread {
    dispatch_once(&oncePredicate, ^{
        _compressThread = [[NSThread alloc] initWithTarget:self selector:@selector(thumbnailThreadEntryPoint:) object:nil];
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
        [ZXLThumbnailManager operationThreadAttemptDealloc];
    }
}


-(void)thumbnailRequest:(ZXLFileInfoModel *)fileModel callback:(ZXLThumbnailCallback)callback{
    if (!fileModel) {
        if (callback) {
            callback(nil,@"数据为空");
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.addOperationSerialQueue, ^{
        ZXLThumbnailOperation * operation = [weakSelf isThumbnailRequestFile:fileModel.identifier];
        if (operation) {
            [operation addThumbnailRequestCallback:callback];
        }else{
            operation = [[ZXLThumbnailOperation alloc] initWithFileModel:fileModel callback:callback];
            [weakSelf.operationQueue addOperation:operation];
        }
    });
}

- (ZXLThumbnailOperation *)isThumbnailRequestFile:(NSString *)fileIdentifier {
    if (!ZXLISNSStringValid(fileIdentifier)) return nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", fileIdentifier];
    NSArray *filterResult = [self.operationQueue.operations filteredArrayUsingPredicate:predicate];
    if (filterResult.count > 0) {
        return (ZXLThumbnailOperation *)[filterResult firstObject];
    }
    return nil;
}

-(void)cancelImageRequestOperationForIdentifier:(NSString *)fileIdentifier{
    ZXLThumbnailOperation * operation = [self isThumbnailRequestFile:fileIdentifier];
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
