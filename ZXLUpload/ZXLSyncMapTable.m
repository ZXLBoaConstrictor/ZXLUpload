//
//  ZXLSyncMapTable.m
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "ZXLSyncMapTable.h"
@interface ZXLSyncMapTable ()
@property (nonatomic, strong) NSMapTable *mapTable;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@end

@implementation ZXLSyncMapTable
+(instancetype)mapTableWithKeyOptions:(NSPointerFunctionsOptions)keyOptions valueOptions:(NSPointerFunctionsOptions)valueOptions{
    ZXLSyncMapTable * syncMapTable = [[ZXLSyncMapTable alloc] init];
    syncMapTable.mapTable = [NSMapTable mapTableWithKeyOptions:keyOptions valueOptions:valueOptions];
    return syncMapTable;
}

-(dispatch_queue_t)dispatchQueue{
    if (!_dispatchQueue) {
        _dispatchQueue = dispatch_queue_create("com.zxlupload.zxlsyncmaptable", DISPATCH_QUEUE_SERIAL);
    }
    return _dispatchQueue;
}


- (id)objectForKey:(id)aKey {
    if (!aKey) {
        return nil;
    }
    
    __block id returnObject = nil;
    dispatch_sync(self.dispatchQueue, ^{
        returnObject = [self.mapTable objectForKey:aKey];
    });
    return returnObject;
}

- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey {
    if (!anObject || !aKey) {
        return;
    }
    
    dispatch_sync(self.dispatchQueue, ^{
        [self.mapTable setObject:anObject forKey:aKey];
    });
}

- (void)removeObjectForKey:(id)aKey {
    if (!aKey) {
        return;
    }
    
    dispatch_sync(self.dispatchQueue, ^{
        [self.mapTable removeObjectForKey:aKey];
    });
}
- (void)removeAllObjects{
    dispatch_sync(self.dispatchQueue, ^{
        [self.mapTable removeAllObjects];
    });
}
@end
