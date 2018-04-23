//
//  ZXLCompressOperation.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//#import <AssetsLibrary/AssetsLibrary.h>

typedef void (^ZXLComprssCallback)(NSString *outputPath,NSString *error);
typedef void (^ZXLComprssProgressCallback)(float percent);

@interface ZXLCompressOperation : NSOperation
@property (nonatomic, copy) NSString *identifier;

-(instancetype)initWithVideoAsset:(AVURLAsset *)asset
                   fileIdentifier:(NSString *)fileId
                 progressCallback:(ZXLComprssProgressCallback)progressCallback
                         Callback:(ZXLComprssCallback)callback;

- (void)addComprssProgressCallback:(ZXLComprssProgressCallback)progressCallback
                          callback:(ZXLComprssCallback)callback;
@end
