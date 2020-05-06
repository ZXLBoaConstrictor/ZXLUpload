//
//  ZXLSyncMutableArray.m
//  Compass
//
//  Created by 张小龙 on 2018/4/4.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import "ZXLSyncMutableArray.h"
@interface ZXLSyncMutableArray (){
    CFMutableArrayRef _array;
}
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@end
@implementation ZXLSyncMutableArray
-(id)init{
    if (self = [super init]) {
        _array = CFArrayCreateMutable(kCFAllocatorDefault, 0,  &kCFTypeArrayCallBacks);
    }
    return self;
}

-(dispatch_queue_t)dispatchQueue{
    if (!_dispatchQueue) {
        _dispatchQueue = dispatch_queue_create("com.zxlupload.zxlsyncmutablearray", DISPATCH_QUEUE_CONCURRENT);
    }
    return _dispatchQueue;
}

- (NSUInteger)count {
    __block NSUInteger result;
    dispatch_sync(self.dispatchQueue, ^{
        result = CFArrayGetCount(self->_array);
    });
    return result;
}

-(id)firstObject{
    __block id result;
    dispatch_sync(self.dispatchQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        result = 0 < count ? CFArrayGetValueAtIndex(self->_array, 0) : nil;
    });
    return result;
}

-(id)lastObject{
    __block id result;
    dispatch_sync(self.dispatchQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        result = 0 < count ? CFArrayGetValueAtIndex(self->_array, count - 1) : nil;
    });
    return result;
}

- (id)objectAtIndex:(NSUInteger)index {
    __block id result;
    dispatch_sync(self.dispatchQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        result = index<count ? CFArrayGetValueAtIndex(self->_array, index) : nil;
    });
    return result;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index{
    if (!anObject)
        return;
    
    __block NSUInteger blockindex = index;
    dispatch_barrier_async(self.dispatchQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        if (blockindex > count) {
            blockindex = count;
        }
        CFArrayInsertValueAtIndex(self->_array, index, (__bridge const void *)anObject);
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index{
    dispatch_barrier_async(self.dispatchQueue, ^{
        if (index < CFArrayGetCount(self->_array)) {
            CFArrayRemoveValueAtIndex(self->_array, index);
        }
    });
}

- (void)addObject:(id)anObject{
    if (!anObject)
        return;
    
    dispatch_barrier_async(self.dispatchQueue, ^{
        CFArrayAppendValue(self->_array, (__bridge const void *)anObject);
    });
}

- (void)addObjectsFromArray:(NSArray *)otherArray{
    if (!otherArray || otherArray.count == 0)
        return;
    
    dispatch_barrier_async(self.dispatchQueue, ^{
        for (NSInteger i = 0; i < otherArray.count; i++) {
            CFArrayAppendValue(self->_array, (__bridge const void*)[otherArray objectAtIndex:i]);
        }
    });
}

- (void)addObjectsFromArrayAtFirst:(NSArray *)otherArray{
    if (!otherArray || otherArray.count == 0)
        return;
    
    dispatch_barrier_async(self.dispatchQueue, ^{
        CFMutableArrayRef tempArray = CFArrayCreateMutable(kCFAllocatorDefault, otherArray.count,  &kCFTypeArrayCallBacks);
        for (NSInteger i = 0; i < otherArray.count; i++) {
            CFArrayAppendValue(tempArray, (__bridge const void*)[otherArray objectAtIndex:i]);
        }
        CFArrayAppendArray(self->_array, tempArray, CFRangeMake(0, CFArrayGetCount(tempArray)));
    });
}

- (void)removeLastObject {
    dispatch_barrier_async(self.dispatchQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        if (count > 0) {
            CFArrayRemoveValueAtIndex(self->_array, count - 1);
        }
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    if (!anObject)
        return;
    
    dispatch_barrier_async(self.dispatchQueue, ^{
        if (index < CFArrayGetCount(self->_array) ) {
            CFArraySetValueAtIndex(self->_array, index, (__bridge const void*)anObject);
        }
    });
}

#pragma mark Optional
- (void)removeAllObjects{
    dispatch_barrier_async(self.dispatchQueue, ^{
        CFArrayRemoveAllValues(self->_array);
    });
}

- (void)removeObject:(id)anObject{
    if (!anObject)
        return;
    
    dispatch_barrier_async(self.dispatchQueue, ^{
        NSInteger result = CFArrayGetFirstIndexOfValue(self->_array, CFRangeMake(0, CFArrayGetCount(self->_array)), (__bridge const void *)(anObject));
        if (result != NSNotFound) {
            CFArrayRemoveValueAtIndex(self->_array, result);
        }
    });
}

- (NSUInteger)indexOfObject:(id)anObject{
    if (!anObject)
        return NSNotFound;
    
    __block NSUInteger result = NSNotFound;
    dispatch_sync(self.dispatchQueue, ^{
        result = CFArrayGetFirstIndexOfValue(self->_array, CFRangeMake(0, CFArrayGetCount(self->_array)), (__bridge const void *)(anObject));
    });
    return result;
}
@end
