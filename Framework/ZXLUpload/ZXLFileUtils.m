//
//  ZXLFileUtils.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLFileUtils.h"
#import "ZXLUploadDefine.h"
#import "ZXLUploadManager.h"
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonCrypto.h>
#define FileHashDefaultChunkSizeForReadingData 1024*8


@implementation ZXLFileUtils
+(NSString *)fileExtension:(ZXLFileType)fileType{
    if (fileType == ZXLFileTypeImage) {
        return @"jpeg";
    }
    
    if (fileType == ZXLFileTypeVideo) {
        return @"mp4";
    }
    
    if (fileType == ZXLFileTypeVoice) {
        return @"mp3";
    }
    
    return @"";
}

+(ZXLFileType)fileTypeByURL:(NSString *)filePath{
    if (!ZXLISNSStringValid(filePath)) return ZXLFileTypeNoFile;
    
    NSString *fileExtension = [filePath pathExtension];
    if (!ZXLISNSStringValid(fileExtension))  return ZXLFileTypeNoFile;
    
    fileExtension = [fileExtension lowercaseString];
    
    //只是加了些常用的文件类型判断，此处可以加更多
    NSString *imageFormat = @"jpg,jpeg,png";
    NSString *videoFormat = @"mp4,mov";
    NSString *voiceFormat = @"mp3,caf,wave";
    
    ZXLFileType fileType = ZXLFileTypeFile;
    if ([imageFormat rangeOfString:fileExtension].location != NSNotFound) {
        fileType = ZXLFileTypeImage;
    }
    
    if ([videoFormat rangeOfString:fileExtension].location != NSNotFound) {
        fileType = ZXLFileTypeVideo;
    }
    
    if ([voiceFormat rangeOfString:fileExtension].location != NSNotFound) {
        fileType = ZXLFileTypeVoice;
    }
    
    return fileType;
}

+(NSInteger)fileSizeByPath:(NSString *)localURL{
    NSInteger fileSize = 0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager]; // default is not thread safe
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:localURL isDirectory:&isDir]){
        if (!isDir) {
            NSError *error = nil;
            NSDictionary *fileDict = [fileManager attributesOfItemAtPath:localURL error:&error];
            if (!error && fileDict){
                fileSize = (NSInteger)[fileDict fileSize];
            }
        }
    }
    return fileSize;
}

+(NSString *)serverAddressFileURL:(NSString *)fileKey
{
    return [NSString stringWithFormat:@"%@%@",[ZXLUploadManager manager].fileServerAddress,fileKey];
}

+(NSString *)fileMd5HashCreateWithPath:(NSString *)filePath{
    if (!filePath || filePath.length < 1) return @"";
    
    return (__bridge_transfer NSString *)ZXLFileMD5HashCreateWithPath((__bridge CFStringRef)filePath, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef ZXLFileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     (CFStringRef)filePath,
                                                     kCFURLPOSIXPathStyle,
                                                     (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);

    done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}


+(NSString *)imageMD5:(UIImage *)image{
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString * base64 = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    if (!base64 || base64.length < 1) return @"";
    
    const char *cStr = [base64 UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (unsigned int)strlen(cStr), result);
    
    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
}

+(NSString *)fileNameWithidentifier:(NSString *)identifier fileExtension:(NSString *)extension{
    return [NSString stringWithFormat:@"%@%@.%@",ZXLFilePrefixion,identifier,extension];
}

+(UIImage *)localVideoThumbnail:(NSString *)path{
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    
    AVAssetImageGenerator *gen = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    
    NSError *error = nil;
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:CMTimeMakeWithSeconds(1.0, 600) actualTime:&actualTime error:&error];
    
    UIImage *thumb = [UIImage imageWithCGImage:image];
    
    CGImageRelease(image);
    
    if (!thumb) {
        thumb = [UIImage imageNamedFromZXLBundle:@"ZXLImageDefault.png"];
    }
    
    return thumb;
}

+(NSString *)base64EncodedString:(NSString *)string{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
   return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

+(NSInteger)fileCMTime:(NSString *)path{
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    CMTime time = [avUrl duration];
    return ceil(time.value/time.timescale);
}
@end

@implementation UIImage (ZXLBundle)

+ (UIImage *)imageNamedFromZXLBundle:(NSString *)name {
    NSString * imagePath = [[NSBundle mainBundle] pathForResource:@"ZXLUpload" ofType:@"bundle"];
    if (ZXLISNSStringValid(imagePath)) {
        return [UIImage imageWithContentsOfFile:[imagePath stringByAppendingPathComponent:name]];
    }
    return nil;
}

-(UIImage*)scaleByFactor:(float)scaleFactor{
    CGSize newSize = CGSizeMake(self.size.width * scaleFactor, self.size.height * scaleFactor);
    size_t destWidth = (size_t)(newSize.width * self.scale);
    size_t destHeight = (size_t)(newSize.height * self.scale);
    if (self.imageOrientation == UIImageOrientationLeft
        || self.imageOrientation == UIImageOrientationLeftMirrored
        || self.imageOrientation == UIImageOrientationRight
        || self.imageOrientation == UIImageOrientationRightMirrored){
        size_t temp = destWidth;
        destWidth = destHeight;
        destHeight = temp;
    }
    
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    BOOL hasAlpha = (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
    
    /// Create an ARGB bitmap context
    CGImageAlphaInfo alphaInfo = (hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst);
    CGContextRef bmContext = CGBitmapContextCreate(NULL, destWidth, destHeight, 8/*Bits per component*/, destWidth * 4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault | alphaInfo);
    
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    
    UIGraphicsPushContext(bmContext);
    CGContextDrawImage(bmContext, CGRectMake(0.0f, 0.0f, destWidth, destHeight), self.CGImage);
    UIGraphicsPopContext();
    
    /// Create an image object from the context
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(scaledImageRef);
    CGContextRelease(bmContext);
    
    return scaled;
}
@end

@implementation NSDictionary (ZXLJSONString)
- (NSString*)JSONString{
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error == nil){
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] ;
    }
    return nil;
}
@end

@implementation NSArray (ZXLJSONString)
- (NSString*)JSONString{
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error == nil){
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] ;
    }
    return nil;
}
@end

@implementation NSString (ZXLJSONString)
- (NSArray *)array{
    id data = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    if ([data isKindOfClass:[NSArray class]]) {
        return data;
    }
    return nil;
}

- (NSDictionary *)dictionary{
    id data = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    if ([data isKindOfClass:[NSDictionary class]]) {
        return data;
    }
    return nil;
}

+ (NSString *)ZXLUploadViewCreateTimeIdentifier{
    return [NSString stringWithFormat:@"ZXLUploadIdentifier%.f",[[NSDate date] timeIntervalSince1970]*1000];
}
@end
