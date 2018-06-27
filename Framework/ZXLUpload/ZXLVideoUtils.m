//
//  ZXLVideoUtils.m
//  ZXLUpload
//  此处代码根据 TZImagePickerController 修改
//  Created by 张小龙 on 2018/1/31.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLVideoUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ZXLVideoUtils

/// 获取视频角度
+ (int)degressFromVideoFileWithAsset:(AVAsset *)asset {
    int degress = 0;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}

// 获取优化后的视频转向信息
+ (AVMutableVideoComposition *)fixedCompositionWithAsset:(AVAsset *)videoAsset {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    // 视频转向
    int degrees = [ZXLVideoUtils degressFromVideoFileWithAsset:videoAsset];
    if (degrees != 0) {
        CGAffineTransform translateToCenter;
        CGAffineTransform mixedTransform;
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        NSArray *tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        if (degrees == 90) {
            // 顺时针旋转90°
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
        } else if(degrees == 180){
            // 顺时针旋转180°
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
        } else {
            // 顺时针旋转270°
            translateToCenter = CGAffineTransformMakeTranslation(0.0, videoTrack.naturalSize.width);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2*3.0);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
        }
        
        AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
        AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        [roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
        
        roateInstruction.layerInstructions = @[roateLayerInstruction];
        // 加入视频方向信息
        videoComposition.instructions = @[roateInstruction];
    }
    return videoComposition;
}

+ (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    CGFloat fullScreenWidth = [UIScreen mainScreen].bounds.size.width;
    if (fullScreenWidth > 600) {
        fullScreenWidth = 600;
    }
    return [ZXLVideoUtils getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:progressHandler networkAccessAllowed:networkAccessAllowed];
}

+ (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    if ([asset isKindOfClass:[PHAsset class]]) {
        
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * 1.0;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);

        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                result = [ZXLVideoUtils fixOrientation:result];
                //                UIImage *resultImage = [UIImage imageWithData:UIImagePNGRepresentation(result) scale:0.1];
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
                        resultImage = [ZXLVideoUtils fixOrientation:resultImage];
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
            
            if (downloadFinined && !result) {
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
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
