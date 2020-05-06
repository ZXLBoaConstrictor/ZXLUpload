//
//  ZXLThumbnailOperation.h
//  ZXLUploadDome
//
//  Created by 张小龙 on 2019/5/15.
//  Copyright © 2019 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXLUploadFileResultCenter.h"

@class ZXLFileInfoModel;

typedef void (^ZXLThumbnailCallback)(UIImage *image,NSString *error);

@interface ZXLThumbnailOperation : NSOperation
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) ZXLFileInfoModel *fileModel;

-(instancetype)initWithFileModel:(ZXLFileInfoModel *)fileModel callback:(ZXLThumbnailCallback)callback;

- (void)addThumbnailRequestCallback:(ZXLThumbnailCallback)callback;
@end
