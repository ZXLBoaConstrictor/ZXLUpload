//
//  ZXLSyncMutableDictionary.h
//  Compass
//
//  Created by 张小龙 on 2018/4/4.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 线程安全字典
 */
@interface ZXLSyncMutableDictionary : NSObject

- (NSInteger)count;
- (id)objectForKey:(id)aKey;
- (NSArray *)allKeys;
- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;
- (void)removeObjectForKey:(id)aKey;
- (void)removeAllObjects;
@end
