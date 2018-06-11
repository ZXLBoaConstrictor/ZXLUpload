//
//  CompressViewController.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/6/1.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "CompressViewController.h"

@interface CompressViewController ()
@property(nonatomic,strong)UIButton * addFilesBtn;
@property(nonatomic,strong)UIButton * compressBtn;
@property(nonatomic,strong)UIButton * contentLabel;
@end

@implementation CompressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
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
    
//    if (!_contentLabel) {
//        _contentLabel =
//    }
    
//    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
//    options.version = PHVideoRequestOptionsVersionOriginal;
//    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
//    options.networkAccessAllowed = YES;
//    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
//        AVURLAsset *videoAsset = (AVURLAsset*)avasset;
//        if (completion) {
//            completion(videoAsset);
//        }
//    }];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addFiles{
    
}

-(void)compress{
    
}
@end
