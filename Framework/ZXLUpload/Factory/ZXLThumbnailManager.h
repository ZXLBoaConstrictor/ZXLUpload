//
//  ZXLThumbnailManager.h
//  ZXLUploadDome
//
//  Created by 张小龙 on 2019/5/15.
//  Copyright © 2019 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZXLFileInfoModel;

typedef void (^ZXLThumbnailCallback)(UIImage *image,NSString *error);

@interface ZXLThumbnailManager : NSObject
+(instancetype)manager;
+ (NSThread *)operationThread;

-(void)thumbnailRequest:(ZXLFileInfoModel *)fileModel callback:(ZXLThumbnailCallback)callback;

@end
