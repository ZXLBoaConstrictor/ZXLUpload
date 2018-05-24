//
//  ZXLDocumentUtils.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLDocumentUtils.h"
#import "ZXLUploadDefine.h"
#import "ZXLFileUtils.h"

@implementation ZXLDocumentUtils

+(NSString *)pathDocumentByName:(NSString *)fileName create:(BOOL)bCreate{
    NSString *documentsDirectory = FILE_DIRECTORY;
    if (!documentsDirectory){
        return nil;
    }
    
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    if(![[NSFileManager defaultManager]fileExistsAtPath:appFile]){
        if(bCreate){
            NSError* error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
            [[NSFileManager defaultManager]createFileAtPath:appFile contents:nil attributes:nil];
        }
        else
            return nil;
    }
    return appFile;
}

+ (NSString *)createFolder:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(![fileManager fileExistsAtPath:path]){
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if(!error){
            NSLog(@"%@",[error description]);
        }
    }
    return path;
}

+ (NSString *)saveImageByName:(UIImage *)image{
    NSString *fileName = [ZXLFileUtils fileNameWithidentifier:[ZXLFileUtils imageMD5:image] fileExtension:[ZXLFileUtils fileExtension:ZXLFileTypeImage]];
    return [ZXLDocumentUtils saveImage:image name:fileName];
}

+ (NSString *)saveImage:(UIImage *)image name:(NSString *)fileName{
    
    if (!image || !ZXLISNSStringValid(fileName)) {
        return @"";
    }
    
    NSString *filePath = FILE_Image_PATH(fileName);
    BOOL bWrite = YES;
    if ([ZXLFileUtils fileSizeByPath:filePath] <= 0) {
        NSData *imageData = UIImagePNGRepresentation(image);
        bWrite = [imageData writeToFile:filePath atomically:YES];
    }
    return bWrite?filePath:@"";
}

+ (NSString *)localFilePath:(NSString *)fileName fileType:(ZXLFileType)fileType{
    NSString *filePath = @"";
    switch (fileType) {
        case ZXLFileTypeImage: filePath = FILE_Image_PATH(fileName); break;
        case ZXLFileTypeVideo: filePath = FILE_Video_PATH(fileName); break;
        case ZXLFileTypeVoice: filePath = FILE_Voice_PATH(fileName); break;
        default: filePath = FILE_Other_PATH(fileName); break;
    }
    return filePath;
}

+(NSString *)takePhotoVideoURL:(NSString *)takePhotoVideoURL{
    NSString *strTemp = @"/tmp/";
    NSRange tempRang = [takePhotoVideoURL rangeOfString:strTemp];
    if (tempRang.location != NSNotFound) {
        takePhotoVideoURL = [takePhotoVideoURL substringFromIndex:tempRang.location + tempRang.length];
        NSString *temp = NSTemporaryDirectory();
        return [temp stringByAppendingPathComponent:takePhotoVideoURL];
    }
    return takePhotoVideoURL;
}

@end
