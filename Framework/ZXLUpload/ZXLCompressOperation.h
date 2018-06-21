//
//  ZXLCompressOperation.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

typedef void (^ZXLComprssCallback)(NSString *outputPath,NSString *error);

@interface ZXLCompressOperation : NSOperation
@property (nonatomic, copy) NSString *identifier;

-(instancetype)initWithVideoAsset:(AVURLAsset *)asset
                   fileIdentifier:(NSString *)fileId
                         callback:(ZXLComprssCallback)callback;

-(instancetype)initWithMp4VideoPHAsset:(PHAsset *)asset
                        fileIdentifier:(NSString *)fileId
                              callback:(ZXLComprssCallback)callback;

- (void)addComprssCallback:(ZXLComprssCallback)callback;

-(float)compressProgress;

+(void)operationThreadAttemptDealloc;
@end
