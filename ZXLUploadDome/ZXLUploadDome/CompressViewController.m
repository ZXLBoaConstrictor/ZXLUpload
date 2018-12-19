//
//  CompressViewController.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/6/1.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "CompressViewController.h"
#import "TZImagePickerController.h"
#import "UICollectionViewLeftAlignedLayout.h"
#import "FilesCollectionViewCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
static NSString *cellIdentifier = @"ZXLUploadFilesCellIdentifier";//文件

@interface CompressViewController ()<TZImagePickerControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(nonatomic,strong)UICollectionView * collectionView;
@property(nonatomic,copy)NSString * uploadIdentifier;
@property(nonatomic,strong)UIButton * addFilesBtn;
@property(nonatomic,strong)UIButton * compressBtn;
@property(nonatomic,strong)UIButton * deleteBtn;
@property(nonatomic,strong)UIButton * contentLabel;
@property(nonatomic,assign)NSInteger uploadFilesCount;
@end

@implementation CompressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.uploadIdentifier = [NSString ZXLUploadViewCreateTimeIdentifier];
    self.uploadFilesCount = 0;
    
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
            make.left.equalTo(@10);
        }];
    }
    
    if (!_compressBtn) {
        _compressBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _compressBtn.layer.borderColor = [UIColor grayColor].CGColor;
        _compressBtn.layer.borderWidth = 1.0f;
        _compressBtn.layer.cornerRadius = 6.0f;
        [_compressBtn setTitle:@"压缩" forState:UIControlStateNormal];
        [_compressBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_compressBtn addTarget:self action:@selector(compress) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_compressBtn];
        [_compressBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@100);
            make.height.equalTo(@40);
            make.top.equalTo(@50);
            make.left.equalTo(self.addFilesBtn.mas_right).offset(20);
        }];
    }
    
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteBtn.layer.borderColor = [UIColor grayColor].CGColor;
        _deleteBtn.layer.borderWidth = 1.0f;
        _deleteBtn.layer.cornerRadius = 6.0f;
        [_deleteBtn setTitle:@"突然删除" forState:UIControlStateNormal];
        [_deleteBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(deleteCompress) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_deleteBtn];
        [_deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@100);
            make.height.equalTo(@40);
            make.top.equalTo(@50);
            make.left.equalTo(self.compressBtn.mas_right).offset(20);
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addFiles{
    typeof(self) __weak weakSelf = self;
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil  message: nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction: [UIAlertAction actionWithTitle: @"拍视频" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf takePhoto:1];
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"从相册选取" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [weakSelf photos];
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"取消" style: UIAlertActionStyleCancel handler:nil]];
    [self presentViewController: alertController animated: YES completion: nil];
}

-(void)compress{
    ZXLTaskInfoModel * taskModel = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:self.uploadIdentifier];
    __block NSInteger successCount = 0;
 
    NSInteger fileCount = self.uploadFilesCount;
    dispatch_group_t group = dispatch_group_create();
    for (NSInteger i = 0; i < fileCount; i++) {
        ZXLFileInfoModel * fileModel = [taskModel uploadFileAtIndex:i];
        [fileModel videoCompress:^(BOOL bResult) {
   
        }];
//        dispatch_group_enter(group);
//        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [fileModel videoCompress:^(BOOL bResult) {
//                if (bResult) {
//                     successCount ++;
//                }
//                dispatch_group_leave(group);
//            }];
//        });
    }
    
    [[ZXLCompressManager manager] cancelCompressOperations];
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        if (successCount == fileCount) {
//            [SVProgressHUD showSuccessWithStatus:@"压缩成功"];
//        }else{
//            [SVProgressHUD showErrorWithStatus:@"压缩失败"];
//        }
//    });
}

-(void)deleteCompress{
    ZXLTaskInfoModel * taskModel = [[ZXLUploadTaskManager manager] uploadTaskInfoForIdentifier:self.uploadIdentifier];
    [taskModel removeAllUploadFiles];
    self.uploadFilesCount = 0;
    [self.collectionView reloadData];
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
      if([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
          NSURL *videoUrl = (NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
          NSString *videoPath = [videoUrl path];
          ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithFileURL:videoPath];
          [[ZXLUploadTaskManager manager] addUploadFile:model forIdentifier:weakSelf.uploadIdentifier];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf collectionViewInsertFilsCount:1];
        });
    }];
}

@end
