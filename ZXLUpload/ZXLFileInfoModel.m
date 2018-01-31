//
//  ZXLFileInfoModel.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLFileInfoModel.h"
#import "ZXLUploadFileResultCenter.h"
typedef void (^completed)(BOOL bResult);

@interface ZXLFileInfoModel()
@property (nonatomic,copy)completed comprssResult;
@property (nonatomic,strong)NSTimer *timer;
@end

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
    }
    return self;
}


-(NSMutableDictionary *)keyValues{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:_identifier forKey:@"identifier"];
    [dictionary setValue:_localURL forKey:@"localURL"];
    [dictionary setValue:_comprssSuccess?@"1":@"0" forKey:@"comprssSuccess"];
    [dictionary setValue:@(_uploadSize).stringValue forKey:@"size"];
    [dictionary setValue:@(_fileType).stringValue forKey:@"filetype"];
    [dictionary setValue:[NSString stringWithFormat:@"%lf",_progress] forKey:@"progress"];
    [dictionary setValue:@(_progressType).stringValue forKey:@"progressType"];
    [dictionary setValue:@(_uploadResult).stringValue forKey:@"uploadResult"];
    [dictionary setValue:@(_fileTime).stringValue forKey:@"fileTime"];
    [dictionary setValue:_assetLocalIdentifier forKey:@"assetLocalIdentifier"];
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
        self.identifier =                     asset.localIdentifier;
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

-(instancetype)initWithImage:(UIImage *)image{
    if (self = [super init]) {
        self.localURL =                 [ZXLDocumentUtils saveImageByName:image];
        self.identifier =                     [ZXLFileUtils fileMd5HashCreateWithPath:self.localURL];
        self.comprssSuccess =           NO;
        self.uploadSize =               [ZXLFileUtils fileSizeByPath:self.localURL];
        self.fileType =                 ZXLFileTypeImage;
        self.progress =                 0;
        self.progressType =             ZXLFileUploadProgressStartUpload;
        self.uploadResult =             ZXLFileUploadloading;
        self.fileTime =                 0;
        self.assetLocalIdentifier =     @"";
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
            self.localURL = [ZXLDocumentUtils takePhotoVideoURL:fileURL];
            self.fileType =                 ZXLFileTypeVideo;
        }else
        {
            self.fileType =                 [ZXLFileUtils fileTypeByURL:fileURL];
            //路径筛查检测
            self.localURL = [ZXLDocumentUtils localFilePath:[fileURL lastPathComponent] fileType:self.fileType];
        }
        
        self.identifier =                     [ZXLFileUtils fileMd5HashCreateWithPath:self.localURL];
        self.comprssSuccess =           NO;
        self.uploadSize =               [ZXLFileUtils fileSizeByPath:self.localURL];
        self.progress =                 0;
        self.progressType =             ZXLFileUploadProgressStartUpload;
        self.uploadResult =             ZXLFileUploadloading;
        self.fileTime =                 0;
        self.assetLocalIdentifier =     @"";
    }
    return self;
}

+(NSMutableArray<ZXLFileInfoModel *> *)initWithAssets:(NSMutableArray <PHAsset *> *)assets{
    return nil;
}

+(NSMutableArray<ZXLFileInfoModel *> *)initWithImages:(NSArray<UIImage *> *)ayImages{
    return nil;
}

-(void)dealloc{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

-(void)waitcomprssResult{
    //检测同一文件是否有压缩成功过
    ZXLFileInfoModel * successComprssFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkComprssSuccessFileInfo:self.identifier];
    if (successComprssFileInfo) {
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        
        self.comprssSuccess = YES;
        self.uploadSize = successComprssFileInfo.uploadSize;
        _comprssResult(YES);
    }
}

-(void)stopVideoCompress{
    if (self.fileType == ZXLFileTypeVideo) {
        
        //停止并清空session
        AVAssetExportSession *exportSession = [[ZXLUploadFileResultCenter shareUploadResultCenter] getAVAssetExportSession:self.identifier];
        if (exportSession) {
            [exportSession cancelExport];
            [[ZXLUploadFileResultCenter shareUploadResultCenter] removeFileAVAssetExportSession:self.identifier];
            
            //删除压缩过没有压缩完的视频
            NSString * videoName = [self uploadKey];
            NSString *strComprssUrl = FILE_Video_PATH(videoName);
            if ([[NSFileManager defaultManager] fileExistsAtPath:strComprssUrl]) {
                BOOL bRemove = [[NSFileManager defaultManager] removeItemAtPath:strComprssUrl error:nil];
                if (bRemove) {
//                 NSLog(@"删除没有压缩完成的视频%@",strcomprssURL);
                }
            }
        }
    }
}

-(void)videoCompress:(void (^)(BOOL bResult ))completed{
    //非视频文件直接返回
    if (self.fileType != ZXLFileTypeVideo) {
        completed(NO);
        return;
    }
    
    //检测同一文件是否有压缩成功过
    ZXLFileInfoModel * successComprssFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkComprssSuccessFileInfo:self.identifier];
    if (successComprssFileInfo) {
        self.comprssSuccess = YES;
        self.uploadSize = successComprssFileInfo.uploadSize;
        completed(YES);
        return;
    }
    
    //有视频文件正在压缩还上传的地方等待视频压缩完成
    ZXLFileInfoModel * progressComprssFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkComprssProgressFileInfo:self.identifier];
    if (progressComprssFileInfo) {
        self.progressType = ZXLFileUploadProgressTranscoding;
        _comprssResult = completed;
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(waitcomprssResult) userInfo:nil repeats:YES];
        
        return;
    }
    
    typeof(self) __weak weakSelf = self;
    if (ISNSStringValid(self.assetLocalIdentifier)) {//相册
        __block PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:self.assetLocalIdentifier] options:nil].firstObject;
        [self getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath, NSString *error) {
            if (!ISNSStringValid(error) && ISNSStringValid(outputPath)) {
                weakSelf.comprssSuccess = YES;
                weakSelf.uploadSize = [ZXLFileUtils fileSizeByPath:outputPath];
                [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssSuccess:weakSelf];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completed) {
                        completed(YES);
                    }
                });
            }else
            {
                //文件信息错误
                [weakSelf setUploadResultError:ZXLFileUploadFileError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completed) {
                        completed(NO);
                    }
                });
            }
        }];
        
    }else//本地
    {
        self.localURL = [ZXLDocumentUtils takePhotoVideoURL:self.localURL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.localURL]) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.localURL]];
            [self startExportVideoWithVideoAsset:asset completion:^(NSString *outputPath, NSString *error) {
                if (!ISNSStringValid(error) && ISNSStringValid(outputPath)) {
                    weakSelf.comprssSuccess = YES;
                    weakSelf.uploadSize = [ZXLFileUtils fileSizeByPath:outputPath];
                    [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssSuccess:weakSelf];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completed) {
                            completed(YES);
                        }
                    });
                }else
                {
                    [weakSelf setUploadResultError:ZXLFileUploadFileError];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completed) {
                            completed(NO);
                        }
                    });
                }
            }];
        }else
        {
            [weakSelf setUploadResultError:ZXLFileUploadFileError];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completed) {
                    completed(NO);
                }
            });
        }
    }
}

/**
 导出相册视频
 
 @param asset 相册索引
 @param completion 导出结果
 */
- (void)getVideoOutputPathWithAsset:(id)asset  completion:(void (^)(NSString *outputPath,NSString *error))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
            AVURLAsset *videoAsset = (AVURLAsset*)avasset;
            [self startExportVideoWithVideoAsset:videoAsset completion:completion];
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        NSURL *videoURL = [asset valueForProperty:ALAssetPropertyAssetURL]; // ALAssetPropertyURLs
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        [self startExportVideoWithVideoAsset:videoAsset completion:completion];
    }
}

/**
 压缩导出视频为MP4
 
 @param videoAsset 视频地址
 @param completion 导出结果
 */
- (void)startExportVideoWithVideoAsset:(AVURLAsset *)videoAsset completion:(void (^)(NSString *outputPath,NSString *error))completion {
    // Find compatible presets by video asset.
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    
    if ([presets containsObject:AVAssetExportPreset640x480]) {
        //转码中
        self.progressType = ZXLFileUploadProgressTranscoding;
        
        AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:videoAsset presetName:AVAssetExportPreset640x480];
        
        __block NSString * videoName = [self uploadKey];
        __block NSString *resultPath = FILE_Video_PATH(videoName);
        session.outputURL = [NSURL fileURLWithPath:resultPath];
        
        // Optimize for network use.
        session.shouldOptimizeForNetworkUse = true;
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            completion(@"",@"视频类型暂不支持导出");
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
        }
        
        AVMutableVideoComposition *videoComposition = [ZXLVideoUtils fixedCompositionWithAsset:videoAsset];
        if (videoComposition.renderSize.width) {
            // 修正视频转向
            session.videoComposition = videoComposition;
        }
        
        // Begin to export video to the output path asynchronously.
        [session exportAsynchronouslyWithCompletionHandler:^(void) {
            NSString *errorStr = @"";
            switch (session.status) {
                case AVAssetExportSessionStatusUnknown:
                    errorStr = @"AVAssetExportSessionStatusUnknown";break;
                case AVAssetExportSessionStatusWaiting:
                    errorStr = @"AVAssetExportSessionStatusWaiting"; break;
                case AVAssetExportSessionStatusExporting:
                    errorStr = @"AVAssetExportSessionStatusExporting"; break;
                case AVAssetExportSessionStatusCompleted:
                    errorStr = @""; break;
                case AVAssetExportSessionStatusFailed:
                    errorStr = @"AVAssetExportSessionStatusFailed"; break;
                default: break;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (ISNSStringValid(errorStr)) {
                        completion(@"",errorStr);
                    }else
                    {
                        completion(resultPath,@"");
                    }
                }
            });
        }];
        
        [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssProgress:self ExportSession:session];
    }
}

-(NSString *)localUploadURL{
    NSString *localUploadURL = self.localURL;
    
    ZXLFileFromType fileFrom = ZXLFileFromLoacl;
    NSRange tempRang = [self.localURL rangeOfString:@"/tmp/"];
    if (tempRang.location != NSNotFound){
        fileFrom = ZXLFileFromTakePhoto;
    }
    
    if (fileFrom == ZXLFileFromTakePhoto) {
        localUploadURL = [ZXLDocumentUtils takePhotoVideoURL:self.localURL];
    }else
    {
        localUploadURL = [ZXLDocumentUtils localFilePath:[self.localURL lastPathComponent] fileType:self.fileType];
    }
    
    return localUploadURL;
}

-(NSString *)uploadKey{
    return [ZXLFileUtils fileNameWithidentifier:self.identifier fileType:self.fileType];
}

-(void)setUploadResultSuccess{
    [self fileClear];

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

-(void)resetFileInfo{
    [self stopVideoCompress];
    
    self.progress = 0;
    self.comprssSuccess = NO;
    self.progressType = ZXLFileUploadProgressStartUpload;
    self.uploadResult = ZXLFileUploadloading;
    [[ZXLUploadFileResultCenter shareUploadResultCenter] removeFileInfoUpload:self.identifier];
}

-(void)fileClear{
    NSString *localUploadURL  = [self localUploadURL];
    if (ISNSStringValid(localUploadURL) && [[NSFileManager defaultManager] fileExistsAtPath:localUploadURL]) {
        BOOL bRemove = [[NSFileManager defaultManager] removeItemAtPath:localUploadURL error:nil];
        if (bRemove) {
//            NSLog(@"上传成功删除%@ --%@",uploadFileURL,self.filecomprssURL);
        }
    }
}

@end
