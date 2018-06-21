//
//  ZXLFileInfoModel.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLFileInfoModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ZXLUploadDefine.h"
#import "ZXLPhotosUtils.h"
#import "ZXLVideoUtils.h"
#import "ZXLFileUtils.h"
#import "ZXLDocumentUtils.h"
#import "ZXLUploadFileResultCenter.h"
#import "ZXLUploadTaskManager.h"
#import "ZXLCompressManager.h"
#import "ZXLImageRequestManager.h"


@implementation ZXLFileInfoModel

+(instancetype)dictionary:(NSDictionary *)dictionary{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    if (self = [super init]) {
        self.identifier =                     [dictionary objectForKey:@"identifier"];
        self.localURL =                 [dictionary objectForKey:@"localURL"];
        self.comprssSuccess =           [[dictionary objectForKey:@"comprssSuccess"] boolValue];
        self.uploadSize =               [[dictionary objectForKey:@"uploadSize"] integerValue];
        self.fileType =                 [[dictionary objectForKey:@"fileType"] integerValue];
        self.progress =                 [[dictionary objectForKey:@"progress"] floatValue];
        self.progressType =             [[dictionary objectForKey:@"progressType"] integerValue];
        self.uploadResult =             [[dictionary objectForKey:@"uploadResult"] integerValue];
        self.fileTime =                 [[dictionary objectForKey:@"fileTime"] integerValue];
        self.assetLocalIdentifier =     [dictionary objectForKey:@"assetLocalIdentifier"];
        self.superTaskIdentifier =     [dictionary objectForKey:@"superTaskIdentifier"];
        
    }
    return self;
}


-(NSMutableDictionary *)keyValues{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:_identifier forKey:@"identifier"];
    [dictionary setValue:_localURL forKey:@"localURL"];
    [dictionary setValue:_comprssSuccess?@"1":@"0" forKey:@"comprssSuccess"];
    [dictionary setValue:@(_uploadSize).stringValue forKey:@"uploadSize"];
    [dictionary setValue:@(_fileType).stringValue forKey:@"fileType"];
    [dictionary setValue:[NSString stringWithFormat:@"%lf",_progress] forKey:@"progress"];
    [dictionary setValue:@(_progressType).stringValue forKey:@"progressType"];
    [dictionary setValue:@(_uploadResult).stringValue forKey:@"uploadResult"];
    [dictionary setValue:@(_fileTime).stringValue forKey:@"fileTime"];
    [dictionary setValue:_assetLocalIdentifier forKey:@"assetLocalIdentifier"];
    [dictionary setValue:_superTaskIdentifier forKey:@"superTaskIdentifier"];
    return dictionary;
}

-(instancetype)initWithAsset:(PHAsset *)asset{
    if (self = [super init]) {
        
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            self.fileType =                 ZXLFileTypeVideo;
        }
        
        if (asset.mediaType == PHAssetMediaTypeImage) {
            self.fileType =                 ZXLFileTypeImage;
        }
        
        self.localURL =                 @"";
        self.superTaskIdentifier =      @"";
        self.identifier =               [ZXLFileUtils base64EncodedString:asset.localIdentifier];
        self.comprssSuccess =           NO;
        self.uploadSize =               0;
        self.progress =                 0;
        self.progressType =             ZXLFileUploadProgressStartUpload;
        self.uploadResult =             ZXLFileUploadloading;
        self.fileTime =                 0;
        self.assetLocalIdentifier =     asset.localIdentifier;
    }
    return self;
}

-(instancetype)initWithUIImagePickerControllerImage:(UIImage *)image{
    UIImage *tempImage = [image scaleByFactor:ZXLUIImagePickerControllerImageScale];
    tempImage = [ZXLPhotosUtils fixOrientation:tempImage];
    return [self initWithImage:tempImage];
}

-(instancetype)initWithImage:(UIImage *)image{
    if (self = [super init]) {
        self.localURL =                 [ZXLDocumentUtils saveImageByName:image];
        self.identifier =               [ZXLFileUtils fileMd5HashCreateWithPath:self.localURL];
        self.comprssSuccess =           NO;
        self.uploadSize =               0;
        self.fileType =                 ZXLFileTypeImage;
        self.progress =                 0;
        self.progressType =             ZXLFileUploadProgressStartUpload;
        self.uploadResult =             ZXLFileUploadloading;
        self.fileTime =                 0;
        self.assetLocalIdentifier =     @"";
        self.superTaskIdentifier =      @"";
    }
    
    return self;
}

-(instancetype)initWithFileURL:(NSString *)fileURL{
    if (self = [super init]) {
        
        ZXLFileFromType fileFrom = ZXLFileFromLoacl;
        NSRange tempRang = [fileURL rangeOfString:@"/tmp/"];
        if (tempRang.location != NSNotFound){
            fileFrom = ZXLFileFromTakePhoto;
        }
            
        if (fileFrom == ZXLFileFromTakePhoto) {
            //目前拍摄的支持视频 -- 图片采用存储 initWithImage 格式
            self.localURL =             [ZXLDocumentUtils takePhotoVideoURL:fileURL];
            self.fileType =             ZXLFileTypeVideo;
        }else{
            self.fileType =             [ZXLFileUtils fileTypeByURL:fileURL];
            self.localURL =             fileURL;
        }
        
        self.identifier =               [ZXLFileUtils fileMd5HashCreateWithPath:self.localURL];
        self.comprssSuccess =           NO;
        self.uploadSize =               0;
        self.progress =                 0;
        self.progressType =             ZXLFileUploadProgressStartUpload;
        self.uploadResult =             ZXLFileUploadloading;
        self.fileTime =                 0;
        self.assetLocalIdentifier =     @"";
        self.superTaskIdentifier =      @"";
        
        if (self.fileType == ZXLFileTypeVideo || self.fileType == ZXLFileTypeVoice) {
            self.fileTime =                 [ZXLFileUtils fileCMTime:fileURL];
        }
    }
    return self;
}

+(NSMutableArray<ZXLFileInfoModel *> *)initWithAssets:(NSMutableArray <PHAsset *> *)assets{
    NSMutableArray<ZXLFileInfoModel *> * models = [NSMutableArray array];
    for (PHAsset *asset in assets) {
        [models addObject:[[ZXLFileInfoModel alloc] initWithAsset:asset]];
    }
    return models;
}

+(NSMutableArray<ZXLFileInfoModel *> *)initWithImages:(NSArray<UIImage *> *)ayImages{
    NSMutableArray<ZXLFileInfoModel *> * models = [NSMutableArray array];
    for (UIImage *image in ayImages) {
        [models addObject:[[ZXLFileInfoModel alloc] initWithImage:image]];
    }
    return models;
}

-(void)dealloc{

}

-(void)videoCompress:(void (^)(BOOL bResult ))completed{
    //非视频文件直接返回
    if (self.fileType != ZXLFileTypeVideo) {
        if (completed) {
            completed(NO);
        }
        return;
    }
    
    self.progressType = ZXLFileUploadProgressTranscoding;
    //检测同一文件是否有压缩成功过
    ZXLFileInfoModel * successComprssFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkComprssSuccessFileInfo:self.identifier];
    if (successComprssFileInfo) {
        self.comprssSuccess = YES;
        self.uploadSize = successComprssFileInfo.uploadSize;
        if (completed) {
           completed(YES);
        }
        return;
    }
    
    typeof(self) __weak weakSelf = self;
    [self getVideoOutputAVURLAsset:^(AVURLAsset *asset) {
        if (asset) {
            NSString * fileExtension = [asset.URL.absoluteString pathExtension];
            fileExtension = [fileExtension lowercaseString];
            if ([fileExtension hasSuffix:@"mp4"]) {
                PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:self.assetLocalIdentifier] options:nil].firstObject;
                [[ZXLCompressManager manager] mp4VideoPHAsset:asset fileIdentifier:weakSelf.identifier callback:^(NSString *outputPath, NSString *error) {
                    if (!ZXLISNSStringValid(error) && ZXLISNSStringValid(outputPath)) {
                        weakSelf.comprssSuccess = YES;
                        [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssSuccess:weakSelf];
                        if (completed) {
                            completed(YES);
                        }
                    }else{
                        //文件信息错误
                        [weakSelf setUploadResultError:ZXLFileUploadFileError];
                        if (completed) {
                            completed(NO);
                        }
                    }
                }];
            }else{
                [[ZXLCompressManager manager] videoAsset:asset fileIdentifier:weakSelf.identifier callback:^(NSString *outputPath, NSString *error) {
                    if (!ZXLISNSStringValid(error) && ZXLISNSStringValid(outputPath)) {
                        weakSelf.comprssSuccess = YES;
                        [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssSuccess:weakSelf];
                        if (completed) {
                            completed(YES);
                        }
                    }else{
                        //文件信息错误
                        [weakSelf setUploadResultError:ZXLFileUploadFileError];
                        if (completed) {
                            completed(NO);
                        }
                    }
                }];
            }
        }else{
            [weakSelf setUploadResultError:ZXLFileUploadFileError];
            if (completed) {
                completed(NO);
            }
        }
    }];
}

/**
 导出视频的AVURLAsset 进行压缩

 @param completion 返回结果
 */
-(void)getVideoOutputAVURLAsset:(void (^)(AVURLAsset * asset))completion{
    if (ZXLISNSStringValid(self.assetLocalIdentifier)) {
        __block PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:self.assetLocalIdentifier] options:nil].firstObject;
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
            AVURLAsset *videoAsset = (AVURLAsset*)avasset;
            if (completion) {
                completion(videoAsset);
            }
        }];
    }else{
        self.localURL = [ZXLDocumentUtils takePhotoVideoURL:self.localURL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.localURL]) {
            AVURLAsset *videoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.localURL]];
            if (completion) {
                completion(videoAsset);
            }
        }else{
            if (completion) {
                completion(nil);
            }
        }
    }
}

-(void)albumImageRequest:(void (^)(BOOL bResult ))completed{
    if (self.fileType == ZXLFileTypeImage
        && ZXLISNSStringValid(self.assetLocalIdentifier)
        && !ZXLISNSStringValid(self.localURL)) {
        typeof(self) __weak weakSelf = self;
        [[ZXLImageRequestManager manager] imageRequest:self.assetLocalIdentifier fileIdentifier:self.identifier callback:^(UIImage *image, NSString *error) {
            typeof(self) strongSelf = weakSelf;
            if (!ZXLISNSStringValid(error) && image) {
                strongSelf.localURL = [ZXLDocumentUtils saveImage:image name:[strongSelf uploadKey]];
                if (completed) {
                    completed(YES);
                }
            }else{
                [strongSelf setUploadResultError:ZXLFileUploadFileError];
                if (completed) {
                    completed(NO);
                }
            }
        }];
    }else{
        if (completed) {
            completed(YES);
        }
    }
}

-(NSString *)localUploadURL{
    NSString *localUploadURL = @"";
    if (self.fileType == ZXLFileTypeVideo) {
        NSString * videoName = [self uploadKey];
        localUploadURL = FILE_Video_PATH(videoName);
    }else if (self.fileType == ZXLFileTypeImage){
        if (ZXLISNSStringValid(self.assetLocalIdentifier)) {
            localUploadURL = FILE_Image_PATH([self uploadKey]);
        }else{
           localUploadURL = [ZXLDocumentUtils localFilePath:[self.localURL lastPathComponent] fileType:self.fileType];
        }
    }else{
        localUploadURL = [ZXLDocumentUtils localFilePath:[self.localURL lastPathComponent] fileType:self.fileType];
    }
    
    if (ZXLISNSStringValid(localUploadURL) && [[NSFileManager defaultManager] fileExistsAtPath:localUploadURL]) {
        self.localURL = localUploadURL;
    }else{
        localUploadURL = self.localURL;
    }
    
    self.uploadSize =               [ZXLFileUtils fileSizeByPath:localUploadURL];
    
    return localUploadURL;
}

-(NSString *)uploadKey{
    
    NSString * fileKey = @"";
    if (ZXLISNSStringValid(self.assetLocalIdentifier)) {//相册文件类型固定
        fileKey =  [ZXLFileUtils fileNameWithidentifier:self.identifier fileExtension:[ZXLFileUtils fileExtension:self.fileType]];
    }
    
    if (!ZXLISNSStringValid(fileKey) && ZXLISNSStringValid(self.localURL)) {
        if (self.fileType == ZXLFileTypeVideo) {//所有视频都会压缩成MP4
            fileKey = [ZXLFileUtils fileNameWithidentifier:self.identifier fileExtension:[ZXLFileUtils fileExtension:self.fileType]];
        }else{
            fileKey = [ZXLFileUtils fileNameWithidentifier:self.identifier fileExtension:[self.localURL pathExtension]];
        }
    }
    
    return fileKey;
}

-(void)setUploadResultSuccess{
    self.uploadResult = ZXLFileUploadSuccess;
    //存储上传信息 上传成功
    self.progress = 1.0;
    self.progressType =  ZXLFileUploadProgressUploadEnd;
    //保存文件成功记录
    [[ZXLUploadFileResultCenter shareUploadResultCenter] saveUploadSuccess:self];
}

-(void)setUploadResultError:(ZXLFileUploadType)uploadType{
    self.uploadResult = uploadType;
    //存储上传信息 上传失败
    self.progress = 1.0;
    self.progressType =  ZXLFileUploadProgressUploadEnd;
    //保存文件上传失败记录
    [[ZXLUploadFileResultCenter shareUploadResultCenter] saveUploadError:self];
}

-(void)setUploadStateWithTheSame:(ZXLFileInfoModel *)sameFileInfo{
    if ([self.identifier isEqualToString:sameFileInfo.identifier]) {
        self.uploadResult = sameFileInfo.uploadResult;
        self.progress = sameFileInfo.progress;
        self.progressType =  sameFileInfo.progressType;
        self.localURL =  sameFileInfo.localURL;
        self.uploadSize = MAX(self.uploadSize, sameFileInfo.uploadSize);
        self.comprssSuccess = sameFileInfo.comprssSuccess;
        self.fileTime = sameFileInfo.fileTime;
    }
}

-(void)resetFileInfo{
    self.progress = 0;
    self.comprssSuccess = NO;
    self.progressType = ZXLFileUploadProgressStartUpload;
    self.uploadResult = ZXLFileUploadloading;
    
    if ([[ZXLUploadTaskManager manager] checkRemoveFile:self.superTaskIdentifier file:self.identifier]) {
        [[ZXLUploadFileResultCenter shareUploadResultCenter] removeFileInfoUpload:self.identifier];
    }
}

-(void)getThumbnail:(void (^)(UIImage * image))completed{
    if (self.fileType == ZXLFileTypeImage) {
        if (ZXLISNSStringValid(self.assetLocalIdentifier)) {//相册图片
            [ZXLPhotosUtils getPhotoAlbumThumbnail:self.assetLocalIdentifier complete:^(UIImage *image) {
                if (completed) {
                    completed(image);
                }
            }];
            
            if (!ZXLISNSStringValid(self.localURL)) {
                [self albumImageRequest:^(BOOL bResult) {
                    
                }];
            }
        }else{
            if (completed) {
                completed([UIImage imageWithContentsOfFile:[self localUploadURL]]);
            }
        }
    }
    
    if (self.fileType == ZXLFileTypeVideo) {
        if (ZXLISNSStringValid(self.assetLocalIdentifier)) {//相册数据
            PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:self.assetLocalIdentifier] options:nil].firstObject;
            [ZXLVideoUtils getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if (!isDegraded && completed) {
                    completed(photo);
                }
            } progressHandler:nil networkAccessAllowed:YES];
        }else{
            ZXLFileFromType fileFrom = ZXLFileFromLoacl;
            NSRange tempRang = [self.localURL rangeOfString:@"/tmp/"];
            if (tempRang.location != NSNotFound){
                fileFrom = ZXLFileFromTakePhoto;
            }
            NSString * localURL = @"";
            if (fileFrom == ZXLFileFromTakePhoto) {//拍照视频
                localURL = [ZXLDocumentUtils takePhotoVideoURL:self.localURL];
            }else{//本地视频
                localURL = [ZXLDocumentUtils localFilePath:[self.localURL lastPathComponent] fileType:self.fileType];
            }
            
            if (completed) {
                completed([ZXLFileUtils localVideoThumbnail:localURL]);
            }
        }
    }
    
    if (self.fileType == ZXLFileTypeVoice) {
        if (completed) {
           completed([UIImage imageNamedFromZXLBundle:@"ZXLDefaultVoice.png"]);
        }
    }
}

- (void)networkError{
    if (self.uploadResult == ZXLFileUploadloading && ![[ZXLUploadFileResultCenter shareUploadResultCenter] checkUploadSuccessFileInfo:self.identifier]) {
        [self setUploadResultError:ZXLFileUploadError];
    }
}
@end
