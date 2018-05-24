//
//  ZXLSyncMapTable.h
//  Compass
//
//  Created by 张小龙 on 2018/4/8.
//  Copyright © 2018年 jlb. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 线程安全MapTable
 */
@interface ZXLSyncMapTable : NSObject
+(instancetype)mapTableWithKeyOptions:(NSPointerFunctionsOptions)keyOptions valueOptions:(NSPointerFunctionsOptions)valueOptions;

- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;
- (void)removeObjectForKey:(id)aKey;
- (void)removeAllObjects;
@end
