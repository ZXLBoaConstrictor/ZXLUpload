//
//  ZXLImageRequestOperation.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/6/20.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLImageRequestOperation.h"
#import "ZXLUploadDefine.h"
#import "ZXLSyncHashTable.h"
#import "ZXLPhotosUtils.h"
#import <Photos/Photos.h>

static NSString * const ZXLImageRequestOperationLockName = @"ZXLImageRequestOperationLockName";

@interface ZXLImageRequestOperation()
@property (nonatomic,strong)ZXLSyncHashTable * requestCallback;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, copy) NSArray *runLoopModes;
@property (nonatomic, assign) PHImageRequestID requestID;
@property (nonatomic, copy) NSString *assetLocalIdentifier;
@end

@implementation ZXLImageRequestOperation
@synthesize executing = _executing;
@synthesize finished  = _finished;
@synthesize cancelled = _cancelled;

-(ZXLSyncHashTable *)requestCallback{
    if (!_requestCallback) {
        _requestCallback = [ZXLSyncHashTable hashTableWithOptions:NSHashTableCopyIn];
    }
    return _requestCallback;
}

-(instancetype)initWithIdentifier:(NSString *)assetLocalIdentifier
                   fileIdentifier:(NSString *)fileId
                         callback:(ZXLImageRequestCallback)callback{
    if (self = [super init]) {
        self.assetLocalIdentifier = assetLocalIdentifier;
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = ZXLImageRequestOperationLockName;
        self.runLoopModes = @[NSRunLoopCommonModes];
        [self.requestCallback addObject:callback];
        self.identifier = fileId;
        self.requestID = 0;
    }
    return self;
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

- (void)addImageRequestCallback:(ZXLImageRequestCallback)callback{
    if (callback) {
        [self.requestCallback addObject:callback];
    }
}

#pragma mark - operation
- (void)cancel {
    [self.lock lock];
    if (!self.isCancelled && !self.isFinished) {
        [super cancel];
        [self KVONotificationWithNotiKey:@"isCancelled" state:&_cancelled stateValue:YES];
        [self runSelector:@selector(cancelImageRequest)];
    }
    [self.lock unlock];
    
    if (self.executing) {
        [self finish];
    }
}

- (void)cancelImageRequest{
    if (self.isExecuting && self.requestID != 0) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
    }
    [self.requestCallback removeAllObjects];
}

- (void)start {
    [self.lock lock];
    if (self.isCancelled) {
        [self finish];
        [self.lock unlock];
        return;
    }
    if (self.isFinished || self.isExecuting) {
        [self.lock unlock];
        return;
    }
    [self runSelector:@selector(startImageRequest)];
    [self.lock unlock];
}

- (void)startImageRequest {
    if (self.isCancelled || self.isFinished || self.isExecuting) {
        return;
    }
    [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:YES];
    [self imageRequest];
}

- (void)imageRequest {
    __weak typeof(self) weakSelf = self;
    self.requestID = [ZXLPhotosUtils getPhoto:self.assetLocalIdentifier complete:^(UIImage *image) {
        typeof(self) strongSelf = weakSelf;
        if (image) {
            [strongSelf imageRequestComplete:image error:@""];
        }else{
            [strongSelf imageRequestComplete:nil error:@"获取文件出错"];
        }
    }];
}


-(void)imageRequestComplete:(UIImage *)image error:(NSString *)error{
    for (ZXLImageRequestCallback callback in self.requestCallback.allObjects) {
        if (callback) {
            callback(image,error);
        }
    }
    [self finish];
}

- (void)finish {
    [self.lock lock];
    if (self.isExecuting) {
        [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:NO];
    }
    [self KVONotificationWithNotiKey:@"isFinished" state:&_finished stateValue:YES];
    [self.lock unlock];
    self.requestID = 0;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)KVONotificationWithNotiKey:(NSString *)key state:(BOOL *)state stateValue:(BOOL)stateValue {
    [self.lock lock];
    [self willChangeValueForKey:key];
    *state = stateValue;
    [self didChangeValueForKey:key];
    [self.lock unlock];
}

- (void)runSelector:(SEL)selecotr {
    [self performSelector:selecotr onThread:[[self class] operationThread] withObject:nil waitUntilDone:NO modes:self.runLoopModes];
}

@end
