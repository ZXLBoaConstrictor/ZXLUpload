//
//  ZXLCompressManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
typedef void (^ZXLComprssCallback)(NSString *outputPath,NSString *error);
typedef void (^ZXLComprssProgressCallback)(float percent);


@interface ZXLCompressManager : NSObject

-(void)videoAsset:(AVURLAsset *)asset
   fileIdentifier:(NSString *)fileId
 progressCallback:(ZXLComprssProgressCallback)progressCallback
         Callback:(ZXLComprssCallback)callback;

- (void)cancelCompressOperations;
@end
