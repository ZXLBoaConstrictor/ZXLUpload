//
//  ZXLFileUtils.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLFileUtils.h"
#import <CommonCrypto/CommonCrypto.h>
#define FileHashDefaultChunkSizeForReadingData 1024*8


@implementation ZXLFileUtils
+(NSString *)fileExtension:(ZXLFileType)fileType{
    if (fileType == ZXLFileTypeImage) {
        return @"jpeg";
    }
    
    if (fileType == ZXLFileTypeImage) {
        return @"mp4";
    }
    
    if (fileType == ZXLFileTypeVoice) {
        return @"mp3";
    }
    
    return @"";
}

+(ZXLFileType)fileTypeByURL:(NSString *)filePath{
    ZXLFileType fileType = ZXLFileTypeFile;
    if ([filePath hasSuffix:[ZXLFileUtils fileExtension:ZXLFileTypeImage]]) {
        fileType = ZXLFileTypeImage;
    }
    
    if ([filePath hasSuffix:[ZXLFileUtils fileExtension:ZXLFileTypeImage]]) {
        fileType = ZXLFileTypeImage;
    }
    
    if ([filePath hasSuffix:[ZXLFileUtils fileExtension:ZXLFileTypeImage]]) {
        fileType = ZXLFileTypeImage;
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

+(NSString *)fileNameWithidentifier:(NSString *)identifier fileType:(ZXLFileType)fileType{
    return [NSString stringWithFormat:@"%@%@.%@",ZXLFilePrefixion,identifier,[ZXLFileUtils fileExtension:fileType]];
}
@end
