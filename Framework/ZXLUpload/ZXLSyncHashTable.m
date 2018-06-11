//
//  ZXLSyncHashTable.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/6/8.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLSyncHashTable.h"
@interface ZXLSyncHashTable ()
@property (nonatomic, strong) NSHashTable *hashTable;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@end
@implementation ZXLSyncHashTable
+ (ZXLSyncHashTable *)hashTableWithOptions:(NSPointerFunctionsOptions)options{
    ZXLSyncHashTable * syncHashTable = [[ZXLSyncHashTable alloc] init];
    syncHashTable.hashTable = [NSHashTable hashTableWithOptions:options];
    return syncHashTable;
}

-(dispatch_queue_t)dispatchQueue{
    if (!_dispatchQueue) {
        _dispatchQueue = dispatch_queue_create("com.zxlupload.zxlsynchashtable", DISPATCH_QUEUE_SERIAL);
    }
    return _dispatchQueue;
}

- (void)addObject:(id)object{
    if (!object) {
        return;
    }
    dispatch_sync(self.dispatchQueue, ^{
        [self.hashTable addObject:object];
    });
}

- (void)removeObject:(id)object{
    if (!object) {
        return;
    }
    
    dispatch_sync(self.dispatchQueue, ^{
        [self.hashTable removeObject:object];
    });
}

- (void)removeAllObjects{
    dispatch_sync(self.dispatchQueue, ^{
        [self.hashTable removeAllObjects];
    });
}

- (NSArray *)allObjects{
    __block NSArray *allObjects = nil;
    dispatch_sync(self.dispatchQueue, ^{
        allObjects = [self.hashTable allObjects];
    });
    return allObjects;
}

@end
