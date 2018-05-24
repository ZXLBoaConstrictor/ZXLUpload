//
//  FilesCollectionViewCell.h
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/5/8.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZXLFileInfoModel;

@interface FilesCollectionViewCell : UICollectionViewCell
-(void)setAddFile:(ZXLFileInfoModel *)fileModel;
@end
