//
//  ZXLCompressOperation.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLCompressOperation.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "ZXLDocumentUtils.h"
#import "ZXLFileUtils.h"
#import "ZXLVideoUtils.h"
#import "ZXLUploadDefine.h"
#import "ZXLSyncHashTable.h"

static NSString * const ZXLCompressOperationLockName = @"ZXLCompressOperationLockName";

@interface ZXLCompressOperation()
@property (nonatomic,strong)ZXLSyncHashTable * comprssCallback;
@property (nonatomic,assign)BOOL checkFailed;
@property (nonatomic,assign)BOOL mp4Video;
//mp4
@property (nonatomic,strong)PHAsset * asset;
@property (nonatomic,assign)double mp4Progress;
//非MP4
@property (nonatomic,strong)AVAssetExportSession *compressSession;

@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, copy) NSArray *runLoopModes;
@end

@implementation ZXLCompressOperation
@synthesize executing = _executing;
@synthesize finished  = _finished;
@synthesize cancelled = _cancelled;

-(ZXLSyncHashTable *)comprssCallback{
    if (!_comprssCallback) {
        _comprssCallback = [ZXLSyncHashTable hashTableWithOptions:NSHashTableCopyIn];
    }
    return _comprssCallback;
}

-(instancetype)initWithVideoAsset:(AVURLAsset *)asset
                   fileIdentifier:(NSString *)fileId
                         callback:(ZXLComprssCallback)callback{
    if (self = [super init]) {
        self.checkFailed = NO;
        self.mp4Video = NO;
        self.compressSession = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPreset640x480];
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = ZXLCompressOperationLockName;
        self.runLoopModes = @[NSRunLoopCommonModes];
        [self.comprssCallback addObject:callback];
        self.identifier = fileId;
    }
    return self;
}

-(instancetype)initWithMp4VideoPHAsset:(PHAsset *)asset
                        fileIdentifier:(NSString *)fileId
                              callback:(ZXLComprssCallback)callback{
    if (self = [super init]) {
        self.checkFailed = NO;
        self.mp4Video = YES;
        self.mp4Progress = 0;
        self.asset = asset;
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = ZXLCompressOperationLockName;
        self.runLoopModes = @[NSRunLoopCommonModes];
        [self.comprssCallback addObject:callback];
        self.identifier = fileId;
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

- (void)addComprssCallback:(ZXLComprssCallback)callback{
    if (callback) {
        [self.comprssCallback addObject:callback];
    }
}

#pragma mark - operation
- (void)cancel {
    [self.lock lock];
    if (!self.isCancelled && !self.isFinished) {
        [super cancel];
        [self KVONotificationWithNotiKey:@"isCancelled" state:&_cancelled stateValue:YES];
        [self runSelector:@selector(cancelCompress)];
    }
    [self.lock unlock];
    
    if (self.executing) {
       [self finish];
    }
}

- (void)cancelCompress {
    if (self.isExecuting && !self.mp4Video &&(self.compressSession.status == AVAssetExportSessionStatusWaiting ||self.compressSession.status == AVAssetExportSessionStatusExporting)) {
        
        [self.compressSession cancelExport];
        //中断压缩删除压缩未完成的文件
        NSString * videoName = [ZXLFileUtils fileNameWithidentifier:self.identifier fileExtension:[ZXLFileUtils fileExtension:ZXLFileTypeVideo]];
        NSString *resultPath = FILE_Video_PATH(videoName);
        if (ZXLISNSStringValid(resultPath) && [[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
            BOOL bRemove = [[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
            if (bRemove) {
                
            }
        }
    }
    
    [self.comprssCallback removeAllObjects];
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
    if (self.mp4Video) {
        NSArray *assetResources = [PHAssetResource assetResourcesForAsset:self.asset];
        PHAssetResource *resource = nil;
        for (PHAssetResource *assetRes in assetResources) {
            if (@available(iOS 9.1, *)) {
                if (assetRes.type == PHAssetResourceTypePairedVideo || assetRes.type == PHAssetResourceTypeVideo) {
                    resource = assetRes;
                }
            } else {
                if (assetRes.type == PHAssetResourceTypeVideo) {
                    resource = assetRes;
                }
            }
        }
        
        NSString * videoName = [ZXLFileUtils fileNameWithidentifier:self.identifier fileExtension:[ZXLFileUtils fileExtension:ZXLFileTypeVideo]];
        __block NSString *resultPath = FILE_Video_PATH(videoName);
        PHAssetResourceRequestOptions *requestOptions = [[PHAssetResourceRequestOptions alloc] init];
        requestOptions.networkAccessAllowed = YES;
        requestOptions.progressHandler = ^(double progress) {
            typeof(self) strongSelf = weakSelf;
            strongSelf.mp4Progress = progress;
        };
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:[NSURL fileURLWithPath:resultPath] options:requestOptions completionHandler:^(NSError *_Nullable error) {
            typeof(self) strongSelf = weakSelf;
            strongSelf.mp4Progress = 1.0;
            if (error) {
                [strongSelf comprssComplete:@"" error:[error localizedDescription]];
            } else {
                [strongSelf comprssComplete:resultPath error:@""];
            }
        }];
    }else{
        [self.compressSession exportAsynchronouslyWithCompletionHandler:^{
            typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                NSString *errorStr = @"";
                switch (strongSelf.compressSession.status) {
                    case AVAssetExportSessionStatusUnknown:
                        errorStr = @"AVAssetExportSessionStatusUnknown";break;
                    case AVAssetExportSessionStatusWaiting:
                        errorStr = @"AVAssetExportSessionStatusWaiting"; break;
                    case AVAssetExportSessionStatusExporting:
                        errorStr = @"AVAssetExportSessionStatusExporting"; break;
                    case AVAssetExportSessionStatusCompleted:
                        errorStr = @""; break;
                    case AVAssetExportSessionStatusFailed:
                        errorStr = [strongSelf.compressSession.error localizedDescription]; break;
                    default: break;
                }
                
                if (ZXLISNSStringValid(errorStr)) {
                    [strongSelf comprssComplete:@"" error:errorStr];
                }else{
                    [strongSelf comprssComplete:strongSelf.compressSession.outputURL.absoluteString error:@""];
                }
            }
        }];
    }
}


-(void)comprssComplete:(NSString *)resultPath error:(NSString *)error{
    for (ZXLComprssCallback callback in self.comprssCallback.allObjects) {
        if (callback) {
            callback(resultPath,error);
        }
    }
    [self finish];
}

//视频压缩配置
-(void)assetExportSessionConfig{
    NSString * videoName = [ZXLFileUtils fileNameWithidentifier:self.identifier fileExtension:[ZXLFileUtils fileExtension:ZXLFileTypeVideo]];
    NSString *resultPath = FILE_Video_PATH(videoName);
    if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
    }
    
    if (!self.mp4Video) {
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
        
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.compressSession.asset];
        self.checkFailed = !([compatiblePresets containsObject:AVAssetExportPreset640x480]);
        
        if (self.checkFailed) {
            return;
        }
        
        AVMutableVideoComposition *videoComposition = [ZXLVideoUtils fixedCompositionWithAsset:self.compressSession.asset];
        if (videoComposition.renderSize.width) {       // 修正视频转向
            self.compressSession.videoComposition = videoComposition;
        }
    }else{
        NSArray *assetResources = [PHAssetResource assetResourcesForAsset:self.asset];
        PHAssetResource *resource = nil;
        for (PHAssetResource *assetRes in assetResources) {
            if (@available(iOS 9.1, *)) {
                if (assetRes.type == PHAssetResourceTypePairedVideo || assetRes.type == PHAssetResourceTypeVideo) {
                    resource = assetRes;
                }
            } else {
                if (assetRes.type == PHAssetResourceTypeVideo) {
                    resource = assetRes;
                }
            }
        }
        
        if (!resource) {
            self.checkFailed = YES;
        }
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

-(float)compressProgress{
    if (self.mp4Video) {
        return MAX(0, self.mp4Progress);
    }else{
        if (self.compressSession) {
            return self.compressSession.progress;
        }
    }
    return 0;
}
@end
