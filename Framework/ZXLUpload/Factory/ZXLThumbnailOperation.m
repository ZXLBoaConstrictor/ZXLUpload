//
//  ZXLThumbnailOperation.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2019/5/15.
//  Copyright © 2019 张小龙. All rights reserved.
//

#import "ZXLThumbnailOperation.h"
#import "ZXLUploadFileResultCenter.h"
#import "ZXLUploadDefine.h"
#import "ZXLSyncHashTable.h"
#import "ZXLPhotosUtils.h"
#import "ZXLThumbnailManager.h"
#import <Photos/Photos.h>
#import "ZXLFileInfoModel.h"
#import "ZXLVideoUtils.h"
#import "ZXLDocumentUtils.h"
#import "ZXLFileUtils.h"

static NSString * const ZXLThumbnailOperationLockName = @"ZXLThumbnailOperationLockName";

@interface ZXLThumbnailOperation()
@property (nonatomic,strong)ZXLSyncHashTable * requestCallback;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, copy) NSArray *runLoopModes;
@end

@implementation ZXLThumbnailOperation
@synthesize executing = _executing;
@synthesize finished  = _finished;
@synthesize cancelled = _cancelled;

-(ZXLSyncHashTable *)requestCallback{
    if (!_requestCallback) {
        _requestCallback = [ZXLSyncHashTable hashTableWithOptions:NSHashTableCopyIn];
    }
    return _requestCallback;
}

-(instancetype)initWithFileModel:(ZXLFileInfoModel *)fileModel callback:(ZXLThumbnailCallback)callback{
    if (self = [super init]) {
        self.fileModel = fileModel;
        self.identifier = self.fileModel.identifier;
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = ZXLThumbnailOperationLockName;
        self.runLoopModes = @[NSRunLoopCommonModes];
        [self.requestCallback addObject:callback];
    }
    return self;
}

- (void)addThumbnailRequestCallback:(ZXLThumbnailCallback)callback{
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
        [self runSelector:@selector(cancelThumbnailRequest)];
    }
    [self.lock unlock];
    
    if (self.executing) {
        [self finish];
    }
}

- (void)cancelThumbnailRequest{
    if (self.isExecuting) {
       
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
    [self runSelector:@selector(startThumbnailRequest)];
    [self.lock unlock];
}

- (void)startThumbnailRequest{
    if (self.isCancelled || self.isFinished || self.isExecuting) {
        return;
    }
    [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:YES];
    [self thumbnailRequest];
}

- (void)thumbnailRequest {
    __weak typeof(self) weakSelf = self;
    if (self.fileModel.fileType == ZXLFileTypeImage) {
        if (ZXLISNSStringValid(self.fileModel.assetLocalIdentifier)) {//相册图片
            [ZXLPhotosUtils getPhotoAlbumThumbnail:self.fileModel.assetLocalIdentifier complete:^(UIImage *image) {
                typeof(self) strongSelf = weakSelf;
                if (image) {
                    [strongSelf thumbnailRequestComplete:image error:@""];
                }else{
                    [strongSelf thumbnailRequestComplete:nil error:@"获取文件出错"];
                }
            }];
        }else{
            [self thumbnailRequestComplete:[UIImage imageWithContentsOfFile:[self.fileModel localUploadURL]] error:@""];
        }
    }
    
    if (self.fileModel.fileType == ZXLFileTypeVideo) {
        if (ZXLISNSStringValid(self.fileModel.assetLocalIdentifier)) {//相册数据
            PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:self.fileModel.assetLocalIdentifier] options:nil].firstObject;
            if (asset) {
                [ZXLVideoUtils getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if (!isDegraded) {
                        typeof(self) strongSelf = weakSelf;
                        if (photo) {
                            [strongSelf thumbnailRequestComplete:photo error:@""];
                        }else{
                            [strongSelf thumbnailRequestComplete:nil error:@"获取文件出错"];
                        }
                    }
                } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    if (error) {
                        typeof(self) strongSelf = weakSelf;
                        [strongSelf thumbnailRequestComplete:nil error:@"获取文件出错"];
                    }
                } networkAccessAllowed:YES];
            }else{
                [self thumbnailRequestComplete:nil error:@"获取文件出错"];
            }
        }else{
            ZXLFileFromType fileFrom = ZXLFileFromLoacl;
            NSRange tempRang = [self.fileModel.localURL rangeOfString:@"/tmp/"];
            if (tempRang.location != NSNotFound){
                fileFrom = ZXLFileFromTakePhoto;
            }
            NSString * localURL = @"";
            if (fileFrom == ZXLFileFromTakePhoto) {//拍照视频
                localURL = [ZXLDocumentUtils takePhotoVideoURL:self.fileModel.localURL];
            }else{//本地视频
                localURL = [ZXLDocumentUtils localFilePath:[self.fileModel.localURL lastPathComponent] fileType:self.fileModel.fileType];
            }
        
            [self thumbnailRequestComplete:[ZXLFileUtils localVideoThumbnail:localURL] error:@""];
        }
    }
    
    if (self.fileModel.fileType == ZXLFileTypeVoice) {
        [self thumbnailRequestComplete:[UIImage imageNamedFromZXLBundle:@"ZXLDefaultVoice.png"] error:@""];
    }
}


-(void)thumbnailRequestComplete:(UIImage *)image error:(NSString *)error{
    for (ZXLThumbnailCallback callback in self.requestCallback.allObjects) {
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
    [self performSelector:selecotr onThread:[ZXLThumbnailManager operationThread] withObject:nil waitUntilDone:NO modes:self.runLoopModes];
}

@end
