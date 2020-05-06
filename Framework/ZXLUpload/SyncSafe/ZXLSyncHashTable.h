//
//  ZXLSyncHashTable.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/6/8.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 线程安全HashTable
 */
@interface ZXLSyncHashTable : NSObject
+ (ZXLSyncHashTable *)hashTableWithOptions:(NSPointerFunctionsOptions)options;
- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (void)removeAllObjects;
- (NSArray *)allObjects;
@end
