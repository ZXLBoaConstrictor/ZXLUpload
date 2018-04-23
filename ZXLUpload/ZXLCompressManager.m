//
//  ZXLCompressManager.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLCompressManager.h"
#import "ZXLCompressOperation.h"

@interface ZXLCompressManager ()
@property (nonatomic, strong) NSOperationQueue *compressQueue;
@property (nonatomic, strong) dispatch_queue_t addOperationSerialQueue;
@end

@implementation ZXLCompressManager
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLCompressManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLCompressManager alloc] init];
        _sharedObject.compressQueue = [[NSOperationQueue alloc] init];
        _sharedObject.compressQueue.maxConcurrentOperationCount = 3;//控制压缩视频数量没有实际真实测试过暂定为3个吧
        _sharedObject.addOperationSerialQueue = dispatch_queue_create("com.ZXLUpload.ZXLCompressManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
    });
    return _sharedObject;
}

-(void)videoAsset:(AVURLAsset *)asset
   fileIdentifier:(NSString *)fileId
 progressCallback:(ZXLComprssProgressCallback)progressCallback
         Callback:(ZXLComprssCallback)callback{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.addOperationSerialQueue, ^{
        ZXLCompressOperation * operation = [weakSelf isCompressingFile:fileId];
        if (operation) {
            [operation addComprssProgressCallback:progressCallback callback:callback];
        }else{
            operation = [[ZXLCompressOperation alloc] initWithVideoAsset:asset fileIdentifier:fileId progressCallback:progressCallback Callback:callback];
            [weakSelf.compressQueue addOperation:operation];
        }
    });
}

- (ZXLCompressOperation *)isCompressingFile:(NSString *)fileIdentifier {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", fileIdentifier];
    NSArray *filterResult = [self.compressQueue.operations filteredArrayUsingPredicate:predicate];
    if (filterResult.count > 0) {
        return (ZXLCompressOperation *)[filterResult firstObject];
    }
    return nil;
}

#pragma mark - cancel
- (void)cancelCompressOperations {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.compressQueue cancelAllOperations];
    });
}
@end
