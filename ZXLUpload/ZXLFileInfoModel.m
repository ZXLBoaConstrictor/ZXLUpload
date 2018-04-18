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
#import "ZXLTimer.h"


typedef void (^ZXLFileComprssCallback)(BOOL bResult);
typedef void (^ZXLFileComprssProgressCallback)(CGFloat percent);

@interface ZXLFileInfoModel()
@property (nonatomic,copy)ZXLFileComprssCallback comprssCallback;
@property (nonatomic,copy)ZXLFileComprssProgressCallback comprssProgressCallback;
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,strong)AVAssetExportSession *compressSession;
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
    [dictionary setValue:@(_uploadSize).stringValue forKey:@"uploadSize"];
    [dictionary setValue:@(_fileType).stringValue forKey:@"fileType"];
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
            self.localURL =             [ZXLDocumentUtils takePhotoVideoURL:fileURL];
            self.fileType =             ZXLFileTypeVideo;
        }else{
            self.fileType =             [ZXLFileUtils fileTypeByURL:fileURL];
            //路径筛查检测
            self.localURL =             [ZXLDocumentUtils localFilePath:[fileURL lastPathComponent] fileType:self.fileType];
        }
        
        self.identifier =               [ZXLFileUtils fileMd5HashCreateWithPath:self.localURL];
        self.comprssSuccess =           NO;
        self.uploadSize =               [ZXLFileUtils fileSizeByPath:self.localURL];
        self.progress =                 0;
        self.progressType =             ZXLFileUploadProgressStartUpload;
        self.uploadResult =             ZXLFileUploadloading;
        self.fileTime =                 0;
        self.assetLocalIdentifier =     @"";
        
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
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    self.compressSession = nil;
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
        if (self.comprssProgressCallback) {
            self.comprssProgressCallback(1);
        }
        if (self.comprssCallback) {
          self.comprssCallback(YES);
        }
    }
    
    AVAssetExportSession * progressComprssSession = [[ZXLUploadFileResultCenter shareUploadResultCenter] getAVAssetExportSession:self.identifier];
    if (progressComprssSession && self.comprssProgressCallback) {
        self.comprssProgressCallback(progressComprssSession.progress);
    }
}

-(void)videoCompress:(void (^)(CGFloat percent ))progress complete:(void (^)(BOOL bResult ))completed{
    //非视频文件直接返回
    if (self.fileType != ZXLFileTypeVideo) {
        
        if (progress) {
            progress(1);
        }

        if (completed) {
            completed(NO);
        }
        return;
    }
    
    //检测同一文件是否有压缩成功过
    ZXLFileInfoModel * successComprssFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkComprssSuccessFileInfo:self.identifier];
    if (successComprssFileInfo) {
        self.comprssSuccess = YES;
        self.uploadSize = successComprssFileInfo.uploadSize;
        if (progress) {
            progress(1);
        }
        
        if (completed) {
           completed(YES);
        }
        return;
    }
    
    //有视频文件正在压缩还上传的地方等待视频压缩完成
    ZXLFileInfoModel * progressComprssFileInfo = [[ZXLUploadFileResultCenter shareUploadResultCenter] checkComprssProgressFileInfo:self.identifier];
    if (progressComprssFileInfo) {
        self.progressType = ZXLFileUploadProgressTranscoding;
        self.comprssCallback = completed;
        self.comprssProgressCallback = progress;
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        
        _timer = [ZXLTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(waitcomprssResult) userInfo:nil repeats:YES];
        return;
    }
    
    typeof(self) __weak weakSelf = self;
    if (ZXLISNSStringValid(self.assetLocalIdentifier)) {//相册
        
        self.comprssProgressCallback = progress;
        __block PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObject:self.assetLocalIdentifier] options:nil].firstObject;
        [self getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath, NSString *error) {
            if (!ZXLISNSStringValid(error) && ZXLISNSStringValid(outputPath)) {
                weakSelf.comprssSuccess = YES;
                weakSelf.uploadSize = [ZXLFileUtils fileSizeByPath:outputPath];
                [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssSuccess:weakSelf];
                
                if (progress) {
                    progress(1);
                }
                
                if (completed) {
                    completed(YES);
                }
            }else{
                //文件信息错误
                [weakSelf setUploadResultError:ZXLFileUploadFileError];
                
                if (progress) {
                    progress(1);
                }
                
                if (completed) {
                    completed(NO);
                }
            }
        }];
        
    }else//本地
    {
        self.localURL = [ZXLDocumentUtils takePhotoVideoURL:self.localURL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.localURL]) {
            self.comprssProgressCallback = progress;
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.localURL]];
            [self startExportVideoWithVideoAsset:asset completion:^(NSString *outputPath, NSString *error) {
                if (!ZXLISNSStringValid(error) && ZXLISNSStringValid(outputPath)) {
                    weakSelf.comprssSuccess = YES;
                    weakSelf.uploadSize = [ZXLFileUtils fileSizeByPath:outputPath];
                    [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssSuccess:weakSelf];
                    if (progress) {
                        progress(1);
                    }
                    
                    if (completed) {
                        completed(YES);
                    }
                }else{
                    [weakSelf setUploadResultError:ZXLFileUploadFileError];
                    if (progress) {
                        progress(1);
                    }
                    if (completed) {
                        completed(NO);
                    }
                }
            }];
        }else{
            [weakSelf setUploadResultError:ZXLFileUploadFileError];
            if (progress) {
                progress(1);
            }
            if (completed) {
                completed(NO);
            }
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
                    if (ZXLISNSStringValid(errorStr)) {
                        completion(@"",errorStr);
                    }else{
                        completion(resultPath,@"");
                    }
                }
            });
        }];
        self.compressSession = session;
        [self.compressSession addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
        [[ZXLUploadFileResultCenter shareUploadResultCenter] saveComprssProgress:self ExportSession:session];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context{
    if (object == self.compressSession && [keyPath isEqualToString:@"progress"]) {
        if (self.compressSession.progress < 1) {
            if (self.comprssProgressCallback) {
                self.comprssProgressCallback(self.compressSession.progress);
            }
        }else{
            if (self.comprssProgressCallback) {
                self.comprssProgressCallback(1);
                self.comprssProgressCallback = nil;
            }
            [self.compressSession removeObserver:self forKeyPath:@"progress"];
        }
    }
}

-(NSString *)localUploadURL{
    NSString *localUploadURL = self.localURL;
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
    return localUploadURL;
}

-(NSString *)uploadKey{
    return [ZXLFileUtils fileNameWithidentifier:self.identifier fileType:self.fileType];
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
                typeof(self) __weak weakSelf = self;
                [ZXLPhotosUtils getPhoto:self.assetLocalIdentifier complete:^(UIImage *image) {
                    if (image) {
                       weakSelf.localURL = [ZXLDocumentUtils saveImage:image name:[weakSelf uploadKey]];
                    }
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
        [[ZXLUploadFileResultCenter shareUploadResultCenter] removeFileInfoUpload:self.identifier];
        [self setUploadResultError:ZXLFileUploadError];
    }
}
@end
