//
//  ZXLDocumentUtils.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/29.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLDocumentUtils.h"


@implementation ZXLDocumentUtils
+(NSMutableDictionary *)dictionaryByListName:(NSString *)fileName
{
    if (!ISNSStringValid(fileName))
        return nil;
    NSMutableDictionary* dictconf = nil;
    NSString *filePath = [ZXLDocumentUtils pathDocumentByName:fileName create:YES];
    if(filePath && [filePath length] > 0)
    {
        //读取存储文件到字典
        dictconf = [[NSMutableDictionary dictionary] initWithContentsOfFile:filePath];
        if(dictconf)
            return dictconf;
    }
    return nil;
}

+(BOOL)setDictionaryByListName:(NSMutableDictionary *)dict fileName:(NSString *)fileName
{
    if (!ISNSStringValid(fileName) || !ISDictionaryValid(dict))
        return NO;
    
    NSString *filePath = [ZXLDocumentUtils pathDocumentByName:fileName create:YES];
    if (!ISNSStringValid(filePath))
        return NO;
    
    return ([dict writeToFile:filePath atomically:YES]);
}

+(NSString *)pathDocumentByName:(NSString *)fileName create:(BOOL)bCreate
{
    NSString *documentsDirectory = FILE_DIRECTORY;
    if (!documentsDirectory)
    {
        return nil;
    }
    
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    if(![[NSFileManager defaultManager]fileExistsAtPath:appFile])
    {
        if(bCreate)
        {
            NSError* error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
            [[NSFileManager defaultManager]createFileAtPath:appFile contents:nil attributes:nil];
        }
        else
            return nil;
    }
    return appFile;
}

+ (NSString *)createFolder:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(![fileManager fileExistsAtPath:path])
    {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if(!error)
        {
            NSLog(@"%@",[error description]);
            
        }
    }
    return path;
}

+ (NSString *)saveImageByName:(UIImage *)image
{
    NSString *fileName = [ZXLFileUtils fileNameWithUUID:[ZXLFileUtils imageMD5:image] fileType:ZXLFileTypeImage];
    NSString *filePath = FILE_Image_PATH(fileName);
    BOOL bWrite = YES;
    if ([ZXLFileUtils fileSizeByPath:filePath] <= 0) {
        NSData *imageData = UIImagePNGRepresentation(image);
        bWrite = [imageData writeToFile:filePath atomically:YES];
    }
    return bWrite?filePath:@"";
}

+ (NSString *)localFilePath:(NSString *)fileName fileType:(ZXLFileType)fileType
{
    NSString *filePath = @"";
    switch (fileType) {
        case ZXLFileTypeImage: filePath = FILE_Image_PATH(fileName); break;
        case ZXLFileTypeVideo: filePath = FILE_Video_PATH(fileName); break;
        case ZXLFileTypeVoice: filePath = FILE_Voice_PATH(fileName); break;
        default: filePath = FILE_Other_PATH(fileName); break;
    }
    return filePath;
}

+(NSString *)takePhotoVideoURL:(NSString *)takePhotoVideoURL
{
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
