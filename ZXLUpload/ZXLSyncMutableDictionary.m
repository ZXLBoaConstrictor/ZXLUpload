//
//  ZXLSyncMutableDictionary.m
//  Compass
//
//  Created by 张小龙 on 2018/4/4.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "ZXLSyncMutableDictionary.h"
@interface ZXLSyncMutableDictionary ()
@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@end

@implementation ZXLSyncMutableDictionary

-(NSMutableDictionary *)dictionary{
    if (!_dictionary) {
        _dictionary = [NSMutableDictionary dictionary];
    }
    return _dictionary;
}

-(dispatch_queue_t)dispatchQueue{
    if (!_dispatchQueue) {
        _dispatchQueue = dispatch_queue_create("com.zxlupload.zxlsyncmutabledictionary", DISPATCH_QUEUE_SERIAL);
    }
    return _dispatchQueue;
}

- (NSInteger)count{
    __block NSInteger dictionaryCount = 0;
    dispatch_sync(self.dispatchQueue, ^{
        dictionaryCount = [self.dictionary count];
    });
    return dictionaryCount;
}

- (NSArray *)allKeys {
    __block NSArray *allKeys = nil;
    dispatch_sync(self.dispatchQueue, ^{
        allKeys = [self.dictionary allKeys];
    });
    return allKeys;
}

- (id)objectForKey:(id)aKey {
    if (!aKey) {
        return nil;
    }
    
    __block id returnObject = nil;
    dispatch_sync(self.dispatchQueue, ^{
        returnObject = [self.dictionary objectForKey:aKey];
    });
    return returnObject;
}

- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey {
    if (!anObject || !aKey) {
        return;
    }

    dispatch_sync(self.dispatchQueue, ^{
        [self.dictionary setObject:anObject forKey:aKey];
    });
}

- (void)removeObjectForKey:(id)aKey {
    if (!aKey) {
        return;
    }
    
    dispatch_sync(self.dispatchQueue, ^{
        [self.dictionary removeObjectForKey:aKey];
    });
}
- (void)removeAllObjects{
    dispatch_sync(self.dispatchQueue, ^{
        [self.dictionary removeAllObjects];
    });
}
@end
