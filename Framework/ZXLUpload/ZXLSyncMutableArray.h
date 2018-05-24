//
//  ZXLSyncMutableArray.h
//  Compass
//
//  Created by 张小龙 on 2018/4/4.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 线程安全数组
 */
@interface ZXLSyncMutableArray : NSObject
- (NSUInteger)count;
- (id)firstObject;
- (id)lastObject;
- (id)objectAtIndex:(NSUInteger)index;
- (void)addObject:(id)anObject;
- (void)addObjectsFromArray:(NSArray *)otherArray;
- (void)addObjectsFromArrayAtFirst:(NSArray *)otherArray;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (void)removeAllObjects;
- (void)removeLastObject;
- (void)removeObject:(id)anObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(id)anObject;
@end
