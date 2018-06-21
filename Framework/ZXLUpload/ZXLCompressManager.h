//
//  ZXLCompressManager.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/23.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
typedef void (^ZXLComprssCallback)(NSString *outputPath,NSString *error);

@interface ZXLCompressManager : NSObject
+(instancetype)manager;

-(void)videoAsset:(AVURLAsset *)asset
   fileIdentifier:(NSString *)fileId
         callback:(ZXLComprssCallback)callback;

-(void)mp4VideoPHAsset:(PHAsset *)asset
        fileIdentifier:(NSString *)fileId
              callback:(ZXLComprssCallback)callback;

-(void)cancelCompressOperationForIdentifier:(NSString *)fileIdentifier;

-(void)cancelCompressOperations;

-(BOOL)checkFileCompressing:(NSString *)fileIdentifier;

-(float)compressProgressForIdentifier:(NSString *)fileIdentifier;

@end
