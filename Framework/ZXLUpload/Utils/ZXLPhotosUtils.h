//
//  ZXLPhotosUtils.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/17.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface ZXLPhotosUtils : NSObject
/**
 获取本地相册的缩略图片(支持从iCloud下载缩略图)
 
 @param assetLocalIdentifier 相册的assetLocalIdentifier
 @param complete 缩略图
 */
+(void)getPhotoAlbumThumbnail:(NSString *)assetLocalIdentifier complete:(void (^)(UIImage *image))complete;

+(PHImageRequestID)getPhoto:(NSString *)assetLocalIdentifier complete:(void (^)(UIImage *image))complete;

+ (UIImage *)fixOrientation:(UIImage *)aImage;
@end
