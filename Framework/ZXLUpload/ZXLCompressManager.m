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
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLCompressManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLCompressManager alloc] init];
    });
    return _sharedObject;
}

-(dispatch_queue_t)addOperationSerialQueue{
    if (!_addOperationSerialQueue) {
        _addOperationSerialQueue = dispatch_queue_create("com.ZXLUpload.ZXLCompressManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _addOperationSerialQueue;
}

-(NSOperationQueue *)operationQueue{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = ZXLMaxConcurrentOperationCount;
        [_operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _operationQueue;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object ==self.operationQueue && self.operationQueue.operationCount == 0) {
        [ZXLCompressOperation operationThreadAttemptDealloc];
    }
}

-(void)videoAsset:(AVURLAsset *)asset
   fileIdentifier:(NSString *)fileId
         callback:(ZXLComprssCallback)callback{
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

-(void)mp4VideoPHAsset:(PHAsset *)asset
        fileIdentifier:(NSString *)fileId
              callback:(ZXLComprssCallback)callback{
    if (asset == nil || !ZXLISNSStringValid(fileId)) {
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
