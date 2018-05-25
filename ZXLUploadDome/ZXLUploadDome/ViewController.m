//
//  ViewController.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/5/4.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ViewController.h"
#import "TZImagePickerController.h"
#import "UICollectionViewLeftAlignedLayout.h"
#import "FilesCollectionViewCell.h"
#import "JLBAsyncUploadTaskManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ZXLRecorder.h>

static NSString *cellIdentifier = @"ZXLUploadFilesCellIdentifier";//文件

@interface ViewController ()<TZImagePickerControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ZXLRecorderDelegate>
@property(nonatomic,strong)UIButton * addFilesBtn;
@property(nonatomic,strong)UIButton * recorderBtn;
@property(nonatomic,strong)UICollectionView * collectionView;
@property(nonatomic,copy)NSString * uploadIdentifier;
@property(nonatomic,assign)NSInteger uploadFilesCount;
@property(nonatomic,strong)ZXLRecorder * recorder;
@end

@implementation ViewController
-(ZXLRecorder *)recorder{
    if (!_recorder) {
        _recorder = [[ZXLRecorder alloc] initWithDelegate:self];
        _recorder.maxTime = 20;
    }
    return _recorder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.uploadIdentifier = [NSString ZXLUploadViewCreateTimeIdentifier];
    self.uploadFilesCount = 0;
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"上传" style:UIBarButtonItemStyleDone target:self action:@selector(onTitleBtnRight)];
    
    if (!_addFilesBtn) {
        _addFilesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addFilesBtn.layer.borderColor = [UIColor grayColor].CGColor;
        _addFilesBtn.layer.borderWidth = 1.0f;
        _addFilesBtn.layer.cornerRadius = 6.0f;
        [_addFilesBtn setTitle:@"添加文件" forState:UIControlStateNormal];
        [_addFilesBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_addFilesBtn addTarget:self action:@selector(addFiles) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_addFilesBtn];
        [_addFilesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@100);
            make.height.equalTo(@40);
            make.top.equalTo(@50);
            make.left.equalTo(@50);
        }];
    }
    
    if (!_recorderBtn) {
        _recorderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _recorderBtn.layer.borderColor = [UIColor grayColor].CGColor;
        _recorderBtn.layer.borderWidth = 1.0f;
        _recorderBtn.layer.cornerRadius = 6.0f;
        [_recorderBtn setTitle:@"录音" forState:UIControlStateNormal];
        [_recorderBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_recorderBtn addTarget:self action:@selector(addMP3Files) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_recorderBtn];
        [_recorderBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@100);
            make.height.equalTo(@40);
            make.top.equalTo(@50);
            make.left.equalTo(self.addFilesBtn.mas_right).offset(20);
        }];
    }
    
    
    if (!_collectionView) {
        UICollectionViewLeftAlignedLayout *layout = [[UICollectionViewLeftAlignedLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 12;
        layout.minimumLineSpacing = 8;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height - 120) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.delegate = self;//设置代理
        _collectionView.dataSource = self;//设置数据源
        [self.view addSubview:_collectionView];
        [_collectionView registerClass:[FilesCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
        
        _collectionView.contentInset = UIEdgeInsetsMake(0, 0,64, 0);
    }
}

-(void)addFiles{
    typeof(self) __weak weakSelf = self;
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil  message: nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction: [UIAlertAction actionWithTitle: @"拍照" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf takePhoto:0];
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"拍视频" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf takePhoto:1];
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"从相册选取" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [weakSelf photos];
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"取消" style: UIAlertActionStyleCancel handler:nil]];
    [self presentViewController: alertController animated: YES completion: nil];
}

-(void)addMP3Files{
    if ([self.recorder isRecording]) {
        [self.recorder stop];
        [_recorderBtn setTitle:@"录音" forState:UIControlStateNormal];
        return;
    }
    
    [self.recorder start];
    [_recorderBtn setTitle:@"结束" forState:UIControlStateNormal];
}

-(void)takePhoto:(NSInteger)type{
    UIImagePickerController *pVC = [[UIImagePickerController alloc] init];
    [pVC setSourceType:UIImagePickerControllerSourceTypeCamera];
    pVC.mediaTypes = [NSArray arrayWithObjects:type == 1?(NSString *)kUTTypeMovie:(NSString *)kUTTypeImage, nil];;
    if (type == 1) {
        pVC.videoMaximumDuration = 300;
    }
    pVC.delegate = self;
    pVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self.navigationController presentViewController:pVC animated:YES completion:nil];
}

-(void)photos{
    TZImagePickerController *pVC =  [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    pVC.allowPickingVideo = YES;
    pVC.isSelectOriginalPhoto = YES;
    pVC.photoWidth = 2000;
    pVC.photoPreviewMaxWidth = 2000;
    [self.navigationController presentViewController:pVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section{
    return self.uploadFilesCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    ZXLTaskInfoModel * taskModel = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:self.uploadIdentifier];
    if (taskModel && indexPath.row < self.uploadFilesCount) {
        [((FilesCollectionViewCell *)collectionViewCell) setAddFile:[taskModel uploadFileAtIndex:indexPath.row]];
    }
    return collectionViewCell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat width = (self.view.frame.size.width - 12*4)/3;
    CGFloat hight = width;
    return CGSizeMake(width, hight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(8, 12, 8, 12);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

}


-(void)onTitleBtnRight{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [JLBAsyncUploadTaskManager startUploadForIdentifier:self.uploadIdentifier complete:^(ZXLTaskInfoModel *taskInfo) {
        if (taskInfo) {
            [self submitFinishWithTaskInfo:taskInfo];
        }
    }];
}
//提交后文件上传结果处理
-(void)submitFinishWithTaskInfo:(ZXLTaskInfoModel *)taskInfo{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    
    ZXLUploadTaskType tasktype =  [taskInfo uploadTaskType];
    switch (tasktype) {
        case ZXLUploadTaskSuccess:{
            NSMutableArray *ayFileInfo = [NSMutableArray array];
            for (NSInteger i = 0;i < [taskInfo uploadFilesCount];i++) {
                ZXLFileInfoModel * fileInfo = [taskInfo uploadFileAtIndex:i];
                if (fileInfo) {
                    [ayFileInfo addObject:@{@"time" : @(fileInfo.fileTime).stringValue, @"imgUrl" : [fileInfo uploadKey], @"type" : @(fileInfo.fileType).stringValue}];
                }
            }
            [SVProgressHUD showSuccessWithStatus:@"上传成功"];
        }
            break;
        case ZXLUploadTaskError://上传失败
        {
            [SVProgressHUD showErrorWithStatus:@"上传失败"];
        }
            break;
            
        default:
            break;
    }
}

-(void)collectionViewInsertFilsCount:(NSInteger)fileCount{
    self.uploadFilesCount += fileCount;
    NSMutableArray * ayIndexPath = [NSMutableArray array];
    for (NSUInteger index = self.uploadFilesCount - fileCount; index < self.uploadFilesCount ; index ++) {
        [ayIndexPath addObject:[NSIndexPath indexPathForRow:index inSection:0]];
    }
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:ayIndexPath];
    } completion:^(BOOL finished) {
        [self.collectionView scrollToItemAtIndexPath:ayIndexPath.lastObject atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    }];
}

#pragma mark -- TZImagePickerControllerDelegate 相册选择照片
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto{
    
    NSMutableArray <ZXLFileInfoModel *> *models = [ZXLFileInfoModel initWithAssets:assets];
    [[ZXLUploadTaskManager manager] addUploadFiles:models forIdentifier:self.uploadIdentifier];
    [self collectionViewInsertFilsCount:models.count];
}

#pragma mark -- TZImagePickerControllerDelegate 相册选择视频
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)asset{
    
    ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithAsset:asset];
    [[ZXLUploadTaskManager manager] addUploadFile:model forIdentifier:self.uploadIdentifier];
    [self collectionViewInsertFilsCount:1];
}


#pragma mark -- UIImagePickerControllerDelegate 拍照或录像
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    typeof(self) __weak weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        NSString *mediaType =[info objectForKey:UIImagePickerControllerMediaType];
        //如果是图片
        if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
            UIImage *image = nil;
            if (picker.allowsEditing) {
                image = info[@"UIImagePickerControllerEditedImage"];
            }else{
                image = info[@"UIImagePickerControllerOriginalImage"];
            }
            
            ZXLFileInfoModel *model = picker.allowsEditing?[[ZXLFileInfoModel alloc] initWithImage:image]:[[ZXLFileInfoModel alloc] initWithUIImagePickerControllerImage:image];
            [[ZXLUploadTaskManager manager] addUploadFile:model forIdentifier:weakSelf.uploadIdentifier];
        }
        //如果是录像
        else if([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
            NSURL *mediaURL = info[@"UIImagePickerControllerMediaURL"];
            NSString *thumbPath = [mediaURL.absoluteString substringFromIndex:7];
            
            ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithFileURL:thumbPath];
            [[ZXLUploadTaskManager manager] addUploadFile:model forIdentifier:weakSelf.uploadIdentifier];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf collectionViewInsertFilsCount:1];
        });
    }];
}

- (void)endConvertWithMP3FileName:(NSString *)filePath{
    ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithFileURL:filePath];
    [[ZXLUploadTaskManager manager] addUploadFile:model forIdentifier:self.uploadIdentifier];
    [self collectionViewInsertFilsCount:1];
}

- (void)failRecord{
    [SVProgressHUD showErrorWithStatus:@"录音失败"];
}

@end
