//
//  ZXLImageRequestOperation.h
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/6/20.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ZXLImageRequestCallback)(UIImage *image,NSString *error);

@interface ZXLImageRequestOperation : NSOperation
@property (nonatomic, copy) NSString *identifier;

-(instancetype)initWithIdentifier:(NSString *)assetLocalIdentifier
                   fileIdentifier:(NSString *)fileId
                         callback:(ZXLImageRequestCallback)callback;

- (void)addImageRequestCallback:(ZXLImageRequestCallback)callback;

+(void)operationThreadAttemptDealloc;
@end
