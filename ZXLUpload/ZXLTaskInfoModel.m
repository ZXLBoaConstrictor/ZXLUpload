//
//  ZXLTaskInfoModel.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/1/27.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLTaskInfoModel.h"
@interface ZXLTaskInfoModel ()
@property (nonatomic,strong)NSMutableArray<ZXLFileInfoModel *> * uploadFiles;     //文件上传任务数组
@end

@implementation ZXLTaskInfoModel

+(instancetype)dictionary:(NSDictionary *)dictionary{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    if (self = [super init]) {
        self.identifier     =  [dictionary objectForKey:@"identifier"];
        NSArray *ayFiles    =  [dictionary objectForKey:@"uploadFiles"];
        _uploadFiles = [NSMutableArray array];
        for (NSDictionary *fileDict in ayFiles) {
            [_uploadFiles addObject:[ZXLFileInfoModel dictionary:fileDict]];
        }
    }
    return self;
}

-(NSMutableDictionary *)keyValues{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:_identifier forKey:@"identifier"];
    
    NSMutableArray * ayFileInfo = [NSMutableArray array];
    for (ZXLFileInfoModel *fileInfo in _uploadFiles) {
        [ayFileInfo addObject:[fileInfo keyValues]];
    }
    [dictionary setValue:ayFileInfo forKey:@"uploadFiles"];
    return dictionary;
}

-(float)uploadProgress{
    return 0;
}

-(float)compressProgress{
    return 0;
}

-(ZXLFileUploadType)uploadTaskType{
    return 0;
}

-(long long)uploadFileSize{
  return 0;
}


-(void)addFileInfo:(ZXLFileInfoModel *)fileInfo{
    
}


-(void)addFileInfos:(NSMutableArray<ZXLFileInfoModel *> *)ayFileInfo{
    
}

-(void)insertObjectFirst:(ZXLFileInfoModel *)fileInfo{
    
}

-(void)insertObjectsFirst:(NSMutableArray <ZXLFileInfoModel *> *)ayFileInfo{
    
}

-(void)removeUploadFile:(NSString *)identifier{
    
}

-(void)clearProgress{
    
}

@end
