//
//  ZXLVideoUtils.h
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/31.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ZXLVideoUtils : NSObject

// 获取优化后的视频转向信息
+ (AVMutableVideoComposition *)fixedCompositionWithAsset:(AVAsset *)videoAsset;
@end
