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

@interface ZXLImageRequestManager ()
@property (nonatomic, strong) NSOperationQueue *compressQueue;
@property (nonatomic, strong) dispatch_queue_t addOperationSerialQueue;
@end

@implementation ZXLImageRequestManager

+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLImageRequestManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLImageRequestManager alloc] init];
    });
    return _sharedObject;
}

-(instancetype)init{
    if (self = [super init]) {
        _compressQueue = [[NSOperationQueue alloc] init];
        _compressQueue.maxConcurrentOperationCount = 5;//控制图片获取数量
        [_compressQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
        _addOperationSerialQueue = dispatch_queue_create("com.ZXLUpload.ZXLImageRequestManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object ==self.compressQueue && self.compressQueue.operationCount == 0) {
        [ZXLImageRequestOperation operationThreadAttemptDealloc];
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
            [weakSelf.compressQueue addOperation:operation];
        }
    });
}

- (ZXLImageRequestOperation *)isImageRequestFile:(NSString *)fileIdentifier {
    if (!ZXLISNSStringValid(fileIdentifier)) return nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", fileIdentifier];
    NSArray *filterResult = [self.compressQueue.operations filteredArrayUsingPredicate:predicate];
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
        [weakSelf.compressQueue cancelAllOperations];
    });

}

@end
