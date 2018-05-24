//
//  FilesCollectionViewCell.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/5/8.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "FilesCollectionViewCell.h"
@interface FilesCollectionViewCell()
@property(nonatomic,strong)UIImageView *imageView;
@property(nonatomic,strong)UIImageView *typeView;
@end

@implementation FilesCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        if (!_imageView) {
            _imageView = [[UIImageView alloc] init];
            _imageView.clipsToBounds = YES;
            _imageView.backgroundColor = [UIColor whiteColor];
            _imageView.contentMode = UIViewContentModeScaleAspectFill;
            [self.contentView addSubview:_imageView];
            [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self);
            }];
        }
        
        if (!_typeView) {
            _typeView = [[UIImageView alloc] init];
            _typeView.clipsToBounds = YES;
            _typeView.image = [UIImage imageNamed:@"videoplay.png"];
            _typeView.contentMode = UIViewContentModeScaleAspectFill;
            [self.contentView addSubview:_typeView];
            [_typeView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@40);
                make.center.equalTo(self.imageView);
            }];
            
            _typeView.hidden = YES;
        }
    }
    return self;
}

- (void)prepareForReuse{
    [super prepareForReuse];
    
    self.imageView.image = nil;
}

-(void)setAddFile:(ZXLFileInfoModel *)fileModel{
    if (fileModel) {
        typeof(self) __weak weakSelf = self;
        [fileModel getThumbnail:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.imageView.image = image;
            });
        }];
        
        self.typeView.hidden = (fileModel.fileType != ZXLFileTypeVideo);
    }
}
@end
