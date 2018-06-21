//
//  ZXLPhotosUtils.m
//  ZXLUpload
//  此处代码根据 TZImagePickerController 修改
//  Created by 张小龙 on 2018/4/17.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLPhotosUtils.h"
#import "ZXLUploadDefine.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ZXLPhotosUtils
+(void)getPhotoAlbumThumbnail:(NSString *)assetLocalIdentifier complete:(void (^)(UIImage *image))complete{
    if (!ZXLISNSStringValid(assetLocalIdentifier)){
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:assetLocalIdentifier] options:nil].firstObject;
    if (!asset){
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    [ZXLPhotosUtils getPhotoWithAsset:asset photoWidth:200 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (!isDegraded && complete) {
           complete(photo);
        }
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        
    } networkAccessAllowed:YES];
}

+(PHImageRequestID)getPhoto:(NSString *)assetLocalIdentifier complete:(void (^)(UIImage *image))complete{
    if (!ZXLISNSStringValid(assetLocalIdentifier)){
        if (complete) {
            complete(nil);
        }
        return 0;
    }
    
    PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:assetLocalIdentifier] options:nil].firstObject;
    if (!asset){
        if (complete) {
            complete(nil);
        }
        return 0;
    }
    
    CGFloat fullScreenWidth = [UIScreen mainScreen].bounds.size.width;
    if (fullScreenWidth > 1200) {
        fullScreenWidth = 1200;
    }
    
   return [ZXLPhotosUtils getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (!isDegraded && complete) {
            complete(photo);
        }
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        
    } networkAccessAllowed:YES];
}

+ (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    
    CGFloat screenScale = 2.0;
    if ([UIScreen mainScreen].bounds.size.width > 700) {
        screenScale = 1.5;
    }
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        CGSize imageSize;
        if (photoWidth < [UIScreen mainScreen].bounds.size.width && photoWidth < 1200) {
            CGFloat itemWH = ([UIScreen mainScreen].bounds.size.width - 4) / 4 - 4;
            imageSize = CGSizeMake(itemWH * screenScale, itemWH * screenScale);
        } else {
            PHAsset *phAsset = (PHAsset *)asset;
            CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
            CGFloat pixelWidth = photoWidth * screenScale;
            CGFloat pixelHeight = pixelWidth / aspectRatio;
            imageSize = CGSizeMake(pixelWidth, pixelHeight);
        }
        // 修复获取图片时出现的瞬间内存过高问题
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                result = [ZXLPhotosUtils fixOrientation:result];
                
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
            // Download image from iCloud / 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !result && networkAccessAllowed) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress, error, stop, info);
                        }
                    });
                };
                options.networkAccessAllowed = YES;
                options.resizeMode = PHImageRequestOptionsResizeModeFast;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    UIImage *resultImage = [UIImage imageWithData:imageData];
                    //                    resultImage = [self scaleImage:resultImage toSize:imageSize];
                    if (resultImage) {
                        resultImage = [ZXLPhotosUtils fixOrientation:resultImage];
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
        }];
        return imageRequestID;
    }
    return 0;
}

/// 修正图片转向
+ (UIImage *)fixOrientation:(UIImage *)aImage {
   
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end
