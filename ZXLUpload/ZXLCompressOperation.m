//
//  ZXLCompressOperation.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLCompressOperation.h"
#import <AVFoundation/AVFoundation.h>
#import "ZXLDocumentUtils.h"
#import "ZXLFileUtils.h"
#import "ZXLVideoUtils.h"
#import "ZXLUploadDefine.h"

static NSString * const ZXLCompressOperationLockName = @"ZXLCompressOperationLockName";

@interface ZXLCompressOperation()
@property (nonatomic,strong)NSHashTable * comprssCallback;
@property (nonatomic,strong)NSHashTable * comprssProgressCallback;
@property (nonatomic,strong)AVAssetExportSession *compressSession;
@property (nonatomic,assign)BOOL checkFailed;

@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, copy) NSArray *runLoopModes;
@end

@implementation ZXLCompressOperation
@synthesize executing = _executing;
@synthesize finished  = _finished;
@synthesize cancelled = _cancelled;

-(NSHashTable *)comprssCallback{
    if (!_comprssCallback) {
        _comprssCallback = [NSHashTable hashTableWithOptions:NSHashTableCopyIn];
    }
    return _comprssCallback;
}

-(NSHashTable *)comprssProgressCallback{
    if (!_comprssProgressCallback) {
        _comprssProgressCallback = [NSHashTable hashTableWithOptions:NSHashTableCopyIn];
    }
    return _comprssProgressCallback;
}

-(instancetype)initWithVideoAsset:(AVURLAsset *)asset
                   fileIdentifier:(NSString *)fileId
                 progressCallback:(ZXLComprssProgressCallback)progressCallback
                         Callback:(ZXLComprssCallback)callback{
    if (self = [super init]) {
        self.checkFailed = NO;
        self.compressSession = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPreset640x480];
        [self.compressSession addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = ZXLCompressOperationLockName;
        self.runLoopModes = @[NSRunLoopCommonModes];
    }
    return self;
}

+ (void)compressThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"ZXLCompressAsyncOperation"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)operationThread {
    static NSThread *_compressThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _compressThread = [[NSThread alloc] initWithTarget:self selector:@selector(compressThreadEntryPoint:) object:nil];
        [_compressThread start];
    });
    
    return _compressThread;
}

- (void)addComprssProgressCallback:(ZXLComprssProgressCallback)progressCallback
                          callback:(ZXLComprssCallback)callback{
    if (progressCallback) {
        [self.comprssProgressCallback addObject:progressCallback];
    }
    
    if (callback) {
        [self.comprssCallback addObject:callback];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context{
    if (object == self.compressSession && [keyPath isEqualToString:@"progress"]) {
        if (self.compressSession.progress < 1) {
            [self compressProgress:self.compressSession.progress];
        }
    }
}

#pragma mark - operation
- (void)cancel {
    [self.lock lock];
    if (!self.isCancelled && !self.isFinished) {
        [super cancel];
        [self KVONotificationWithNotiKey:@"isCancelled" state:&_cancelled stateValue:YES];
        if (self.isExecuting) {
            [self runSelector:@selector(cancelCompress)];
        }
    }
    [self.lock unlock];
}

- (void)cancelCompress {
    [self.comprssCallback removeAllObjects];
    [self.comprssProgressCallback removeAllObjects];
    [self.compressSession removeObserver:self forKeyPath:@"progress"];
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
    [self runSelector:@selector(startCompress)];
    [self.lock unlock];
}

- (void)startCompress {
    if (self.isCancelled || self.isFinished || self.isExecuting) {
        return;
    }
    [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:YES];
    [self compressFile];
}

- (void)compressFile {
    [self assetExportSessionConfig];
    
    if (self.checkFailed) {
        [self comprssComplete:@"" error:@"视频类型暂不支持导出"];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.compressSession exportAsynchronouslyWithCompletionHandler:^{
        if (weakSelf) {
            NSString *errorStr = @"";
            switch (weakSelf.compressSession.status) {
                case AVAssetExportSessionStatusUnknown:
                    errorStr = @"AVAssetExportSessionStatusUnknown";break;
                case AVAssetExportSessionStatusWaiting:
                    errorStr = @"AVAssetExportSessionStatusWaiting"; break;
                case AVAssetExportSessionStatusExporting:
                    errorStr = @"AVAssetExportSessionStatusExporting"; break;
                case AVAssetExportSessionStatusCompleted:
                    errorStr = @""; break;
                case AVAssetExportSessionStatusFailed:
                    errorStr = @"AVAssetExportSessionStatusFailed"; break;
                default: break;
            }
            
            if (ZXLISNSStringValid(errorStr)) {
                [weakSelf comprssComplete:@"" error:errorStr];
            }else{
                [weakSelf comprssComplete:weakSelf.compressSession.outputURL.absoluteString error:@""];
            }
        }
    }];
}

-(void)compressProgress:(float)percent{
    for (ZXLComprssProgressCallback progressCallback in self.comprssProgressCallback) {
        if (progressCallback) {
            progressCallback(percent);
        }
    }
}

-(void)comprssComplete:(NSString *)resultPath error:(NSString *)error{
    [self compressProgress:1.0];
    
    for (ZXLComprssCallback callback in self.comprssCallback) {
        if (callback) {
            callback(resultPath,error);
        }
    }
    [self finish];
}

//视频压缩配置
-(void)assetExportSessionConfig{
    __block NSString * videoName = [ZXLFileUtils fileNameWithidentifier:self.identifier fileType:ZXLFileTypeVideo];
    __block NSString *resultPath = FILE_Video_PATH(videoName);
    self.compressSession.outputURL = [NSURL fileURLWithPath:resultPath];
    self.compressSession.shouldOptimizeForNetworkUse = true;
    NSArray *supportedTypeArray =  self.compressSession.supportedFileTypes;
    if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
         self.compressSession.outputFileType = AVFileTypeMPEG4;
    } else if (supportedTypeArray.count == 0) {
        self.checkFailed = YES;
    } else {
         self.compressSession.outputFileType = [supportedTypeArray objectAtIndex:0];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
    }
    AVMutableVideoComposition *videoComposition = [ZXLVideoUtils fixedCompositionWithAsset:self.compressSession.asset];
    if (videoComposition.renderSize.width) {       // 修正视频转向
        self.compressSession.videoComposition = videoComposition;
    }
}

- (void)finish {
    [self.lock lock];
    if (self.isExecuting) {
        [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:NO];
    }
    [self KVONotificationWithNotiKey:@"isFinished" state:&_finished stateValue:YES];
    [self.lock unlock];
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
