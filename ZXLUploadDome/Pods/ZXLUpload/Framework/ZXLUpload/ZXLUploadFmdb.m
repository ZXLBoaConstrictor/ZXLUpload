//
//  ZXLUploadFmdb.m
//  ZXLUpload
//
//  Created by 张小龙 on 2018/4/20.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLUploadFmdb.h"
#import <FMDB/FMDB.h>
#import "ZXLFileUtils.h"
#import "ZXLUploadDefine.h"
#import "ZXLDocumentUtils.h"
#import "ZXLTaskInfoModel.h"
#import "ZXLFileInfoModel.h"

#define ZXLUploadTaskInfoTableName @"zxluploadtaskinfo"

#define ZXLUploadResultInfoTableName @"zxluploadresultinfo"

#define ZXLUploadComprssInfoTableName @"zxluploadcompressinfo"



//--- ZXLTaskInfoModel 需要杀掉进程继续可以上传的任务信息
#define ZXLUploadTaskInfoTableCreateSQL                                     \
@"CREATE TABLE IF NOT EXISTS " ZXLUploadTaskInfoTableName @" ("             \
@"id"                               @" integer primary key autoincrement, " \
@"identifier"                           @" VARCHAR(1024)  NOT NULL, "       \
@"resetUploadType"                      @" INTEGER DEFAULT 0, "             \
@"unifiedResponese"                     @" BOOL DEFAULT FALSE, "            \
@"completeResponese"                    @" BOOL DEFAULT FALSE, "            \
@"storageLocal"                         @" BOOL DEFAULT FALSE, "            \
@"uploading"                            @" BOOL DEFAULT FALSE, "            \
@"uploadFiles"                          @" TEXT NOT NULL "                 \
@")"

#define ZXLUploadTaskInfoTableInsertSQL                                     \
@"INSERT OR IGNORE INTO " ZXLUploadTaskInfoTableName @" ("                  \
@"identifier"                                               @", "           \
@"resetUploadType"                                          @", "           \
@"unifiedResponese"                                         @", "           \
@"completeResponese"                                        @", "           \
@"storageLocal"                                             @", "           \
@"uploading"                                                @", "           \
@"uploadFiles"                                                              \
@") VALUES(?, ?, ?, ?, ?, ?, ?)"

#define ZXLUploadTaskInfoTableDeleteSQL                                     \
@"DELETE FROM " ZXLUploadTaskInfoTableName                                  \
@" WHERE identifier = ?"

#define ZXLUploadTaskInfoTableSelectSQL                                   \
@"SELECT * FROM " ZXLUploadTaskInfoTableName                              \

//--- ZXLFileInfoModel  上传成功的文件信息存储
#define ZXLUploadResultInfoTableCreateSQL                                    \
@"CREATE TABLE IF NOT EXISTS " ZXLUploadResultInfoTableName @" ("            \
@"id"                               @" integer primary key autoincrement, "  \
@"identifier"                           @" VARCHAR(1024)  NOT NULL, "        \
@"localURL"                             @" VARCHAR(1024), "                  \
@"uploadSize"                           @" INTEGER DEFAULT 0, "              \
@"fileType"                             @" INTEGER DEFAULT 0, "              \
@"fileTime"                             @" INTEGER DEFAULT 0,  "             \
@"assetLocalIdentifier"                 @" VARCHAR(255), "                   \
@"superTaskIdentifier"                  @" VARCHAR(1024), "                  \
@"comprssSuccess"                       @" BOOL DEFAULT FALSE, "             \
@"progress"                             @" FLOAT DEFAULT 0,"                  \
@"progressType"                         @" INTEGER DEFAULT 0, "              \
@"uploadResult"                         @" INTEGER DEFAULT 0 "              \
@")"

#define ZXLUploadResultInfoTableInsertSQL                                   \
@"INSERT OR IGNORE INTO " ZXLUploadResultInfoTableName @" ("                \
@"identifier"                                               @", "           \
@"localURL"                                                 @", "           \
@"uploadSize"                                               @", "           \
@"fileType"                                                 @", "           \
@"fileTime"                                                 @", "           \
@"assetLocalIdentifier"                                     @", "           \
@"superTaskIdentifier"                                      @", "           \
@"comprssSuccess"                                           @", "           \
@"progress"                                                 @", "           \
@"progressType"                                             @", "           \
@"uploadResult"                                                             \
@") VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

#define ZXLUploadResultInfoTableDeleteSQL                                   \
@"DELETE FROM " ZXLUploadResultInfoTableName                                \
@" WHERE identifier = ?"

#define ZXLUploadResultInfoTableSelectSQL                                   \
@"SELECT * FROM " ZXLUploadResultInfoTableName                              \


//--- ZXLFileInfoModel 压缩成功的文件信息存储（使用的时候判断文件是否在本地）
#define ZXLUploadComprssInfoTableCreateSQL                                   \
@"CREATE TABLE IF NOT EXISTS " ZXLUploadComprssInfoTableName @" ("           \
@"id"                               @" integer primary key autoincrement, "  \
@"identifier"                           @" VARCHAR(1024)  NOT NULL, "        \
@"localURL"                             @" VARCHAR(1024), "                  \
@"uploadSize"                           @" INTEGER DEFAULT 0, "              \
@"fileType"                             @" INTEGER DEFAULT 0, "              \
@"fileTime"                             @" INTEGER DEFAULT 0,  "             \
@"assetLocalIdentifier"                 @" VARCHAR(255), "                   \
@"superTaskIdentifier"                  @" VARCHAR(1024), "                  \
@"comprssSuccess"                       @" BOOL DEFAULT FALSE, "             \
@"progress"                             @" FLOAT DEFAULT 0,"                  \
@"progressType"                         @" INTEGER DEFAULT 0, "              \
@"uploadResult"                         @" INTEGER DEFAULT 0 "              \
@")"

#define ZXLUploadComprssInfoTableInsertSQL                                   \
@"INSERT OR IGNORE INTO " ZXLUploadComprssInfoTableName @" ("                \
@"identifier"                                               @", "            \
@"localURL"                                                 @", "            \
@"uploadSize"                                               @", "            \
@"fileType"                                                 @", "            \
@"fileTime"                                                 @", "            \
@"assetLocalIdentifier"                                     @", "            \
@"superTaskIdentifier"                                      @", "            \
@"comprssSuccess"                                           @", "            \
@"progress"                                                 @", "            \
@"progressType"                                             @", "            \
@"uploadResult"                                                              \
@") VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

#define ZXLUploadComprssInfoTableDeleteSQL                                   \
@"DELETE FROM " ZXLUploadComprssInfoTableName                                \
@" WHERE identifier = ?"

#define ZXLUploadComprssInfoTableSelectSQL                                   \
@"SELECT * FROM " ZXLUploadComprssInfoTableName                              \


@interface ZXLUploadFmdb ()
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) dispatch_queue_t sqliteQueue;
@end

@implementation ZXLUploadFmdb
+(ZXLUploadFmdb*)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLUploadFmdb * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[ZXLUploadFmdb alloc] init];
        [_sharedObject creatDatabase];
    });
    return _sharedObject;
}

- (dispatch_queue_t)sqliteQueue{
    if (!_sqliteQueue) {
        _sqliteQueue = dispatch_queue_create("com.zxlupload.sqliteQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _sqliteQueue;
}

-(void)creatDatabase{
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:ZXLUploadFmdbPath];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL success =  [db executeUpdate:ZXLUploadTaskInfoTableCreateSQL];
        if (success) {
            ZXLUploadLog(@"上传任务表创建成功");
        }
        success = [db executeUpdate:ZXLUploadResultInfoTableCreateSQL];
        if (success) {
            ZXLUploadLog(@"上传文件成功信息表创建成功");
        }
        success = [db executeUpdate:ZXLUploadComprssInfoTableCreateSQL];
        if (success) {
            ZXLUploadLog(@"压缩文件成功信息表创建成功");
        }
    }];
}

-(void)insertUploadTaskInfo:(ZXLTaskInfoModel *)taskModel{
    if (!taskModel) return;
    
    NSArray *arguments = @[taskModel.identifier,
                           @(taskModel.resetUploadType),
                           @(taskModel.unifiedResponese),
                           @(taskModel.completeResponese),
                           @(taskModel.storageLocal),
                           @(taskModel.uploading),
                           [taskModel filesJSONString]];
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:ZXLUploadTaskInfoTableInsertSQL withArgumentsInArray:arguments];
            if (!success) {
                ZXLUploadLog(@"插入上传任务失败");
            }
        }];
    });
}

-(void)insertUploadSuccessFileResultInfo:(ZXLFileInfoModel *)fileModel{
    if (!fileModel) return;
    
    NSArray *arguments = @[fileModel.identifier,
                           fileModel.localURL,
                           @(fileModel.uploadSize),
                           @(fileModel.fileType),
                           @(fileModel.fileTime),
                           fileModel.assetLocalIdentifier,
                           fileModel.superTaskIdentifier,
                           @(fileModel.comprssSuccess),
                           @(fileModel.progress),
                           @(fileModel.progressType),
                           @(fileModel.uploadResult)];
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:ZXLUploadResultInfoTableInsertSQL withArgumentsInArray:arguments];
            if (!success) {
                ZXLUploadLog(@"插入上传成功文件信息失败");
            }
        }];
    });
}

-(void)insertCompressFileInfo:(ZXLFileInfoModel *)fileModel{
    if (!fileModel) return;
    
    NSArray *arguments = @[fileModel.identifier,
                           fileModel.localURL,
                           @(fileModel.uploadSize),
                           @(fileModel.fileType),
                           @(fileModel.fileTime),
                           fileModel.assetLocalIdentifier,
                           fileModel.superTaskIdentifier,
                           @(fileModel.comprssSuccess),
                           @(fileModel.progress),
                           @(fileModel.progressType),
                           @(fileModel.uploadResult)];
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:ZXLUploadComprssInfoTableInsertSQL withArgumentsInArray:arguments];
            if (!success) {
                ZXLUploadLog(@"插入压缩成功文件信息失败");
            }
        }];
    });
}

//删
-(void)deleteUploadTaskInfo:(ZXLTaskInfoModel *)taskModel{
    NSArray *arguments = @[taskModel.identifier];
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:ZXLUploadTaskInfoTableDeleteSQL withArgumentsInArray:arguments];
            if (!success) {
                ZXLUploadLog(@"删除上传任务失败");
            }
        }];
    });
}

-(void)deleteUploadSuccessFileResultInfo:(ZXLFileInfoModel *)fileModel{
    NSArray *arguments = @[fileModel.identifier];
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:ZXLUploadResultInfoTableDeleteSQL withArgumentsInArray:arguments];
            if (!success) {
                ZXLUploadLog(@"删除上传成功文件信息失败");
            }
        }];
    });
}

-(void)deleteCompressFileInfo:(ZXLFileInfoModel *)fileModel{
    NSArray *arguments = @[fileModel.identifier];
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:ZXLUploadComprssInfoTableDeleteSQL withArgumentsInArray:arguments];
            if (!success) {
                ZXLUploadLog(@"删除压缩成功文件信息失败");
            }
        }];
    });
}

-(void)clearUploadTaskInfo{
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@",ZXLUploadTaskInfoTableName]];
            if (!success) {
                ZXLUploadLog(@"清空上传任务失败");
            }
        }];
    });
}

-(void)clearUploadSuccessFileResultInfo{
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@",ZXLUploadResultInfoTableName]];
            if (!success) {
                ZXLUploadLog(@"清空上传成功文件信息失败");
            }
        }];
    });
}

-(void)clearCompressFileInfo{
    dispatch_async(self.sqliteQueue, ^{
        [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            BOOL success = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@",ZXLUploadComprssInfoTableName]];
            if (!success) {
                ZXLUploadLog(@"清空上传任务失败");
            }
        }];
    });
}

//查(全部)
-(NSMutableArray<ZXLTaskInfoModel *> *)selectAllUploadTaskInfo{
    __block NSMutableArray<ZXLTaskInfoModel *> * taskModels = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet* resultSet = [db executeQuery:ZXLUploadTaskInfoTableSelectSQL];
        while ([resultSet next]) {
            NSMutableDictionary *taskDictionary = [NSMutableDictionary dictionary];
            [taskDictionary setObject:[resultSet stringForColumn:@"identifier"] forKey:@"identifier"];
            [taskDictionary setObject:@([resultSet intForColumn:@"resetUploadType"]) forKey:@"resetUploadType"];
            [taskDictionary setObject:@([resultSet boolForColumn:@"unifiedResponese"]) forKey:@"unifiedResponese"];
            [taskDictionary setObject:@([resultSet boolForColumn:@"completeResponese"]) forKey:@"completeResponese"];
            [taskDictionary setObject:@([resultSet boolForColumn:@"storageLocal"]) forKey:@"storageLocal"];
            [taskDictionary setObject:@([resultSet boolForColumn:@"uploading"]) forKey:@"uploading"];
            NSMutableArray *files = [NSMutableArray array];
            NSArray *jsonFiles = [[resultSet stringForColumn:@"uploadFiles"] array];
            for (NSInteger i = 0;i < jsonFiles.count;i++) {
                NSDictionary *jsonDictionary = [((NSString *)[jsonFiles objectAtIndex:i]) dictionary];
                if (ZXLISDictionaryValid(jsonDictionary)) {
                    [files addObject:jsonDictionary];
                }
            }
            [taskDictionary setObject:files forKey:@"uploadFiles"];
            [taskModels addObject:[ZXLTaskInfoModel dictionary:taskDictionary]];
        }
    }];
    return taskModels;
}

-(NSMutableArray<ZXLFileInfoModel *> *)selectAllUploadSuccessFileResultInfo{
    __block NSMutableArray<ZXLFileInfoModel *> * fileModels = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet* resultSet = [db executeQuery:ZXLUploadResultInfoTableSelectSQL];
        while ([resultSet next]) {
            NSMutableDictionary *fileDictionary = [NSMutableDictionary dictionary];
            [fileDictionary setValue:[resultSet stringForColumn:@"identifier"] forKey:@"identifier"];
            [fileDictionary setValue:[resultSet stringForColumn:@"localURL"] forKey:@"localURL"];
            [fileDictionary setValue:@([resultSet boolForColumn:@"comprssSuccess"]) forKey:@"comprssSuccess"];
            [fileDictionary setValue:@([resultSet longForColumn:@"uploadSize"]) forKey:@"uploadSize"];
            [fileDictionary setValue:@([resultSet intForColumn:@"fileType"]) forKey:@"fileType"];
            [fileDictionary setValue:@([resultSet doubleForColumn:@"progress"]) forKey:@"progress"];
            [fileDictionary setValue:@([resultSet intForColumn:@"progressType"]) forKey:@"progressType"];
            [fileDictionary setValue:@([resultSet intForColumn:@"uploadResult"]) forKey:@"uploadResult"];
            [fileDictionary setValue:@([resultSet intForColumn:@"fileTime"]) forKey:@"fileTime"];
            [fileDictionary setValue:[resultSet stringForColumn:@"assetLocalIdentifier"] forKey:@"assetLocalIdentifier"];
            [fileDictionary setValue:[resultSet stringForColumn:@"superTaskIdentifier"] forKey:@"superTaskIdentifier"];
            [fileModels addObject:[ZXLFileInfoModel dictionary:fileDictionary]];
        }
    }];
    return fileModels;
}

-(NSMutableArray<ZXLFileInfoModel *> *)selectAllCompressFileInfo{
    __block NSMutableArray<ZXLFileInfoModel *> * fileModels = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet* resultSet = [db executeQuery:ZXLUploadComprssInfoTableSelectSQL];
        while ([resultSet next]) {
            NSMutableDictionary *fileDictionary = [NSMutableDictionary dictionary];
            [fileDictionary setValue:[resultSet stringForColumn:@"identifier"] forKey:@"identifier"];
            [fileDictionary setValue:[resultSet stringForColumn:@"localURL"] forKey:@"localURL"];
            [fileDictionary setValue:@([resultSet boolForColumn:@"comprssSuccess"]) forKey:@"comprssSuccess"];
            [fileDictionary setValue:@([resultSet longForColumn:@"uploadSize"]) forKey:@"uploadSize"];
            [fileDictionary setValue:@([resultSet intForColumn:@"fileType"]) forKey:@"fileType"];
            [fileDictionary setValue:@([resultSet doubleForColumn:@"progress"]) forKey:@"progress"];
            [fileDictionary setValue:@([resultSet intForColumn:@"progressType"]) forKey:@"progressType"];
            [fileDictionary setValue:@([resultSet intForColumn:@"uploadResult"]) forKey:@"uploadResult"];
            [fileDictionary setValue:@([resultSet intForColumn:@"fileTime"]) forKey:@"fileTime"];
            [fileDictionary setValue:[resultSet stringForColumn:@"assetLocalIdentifier"] forKey:@"assetLocalIdentifier"];
            [fileDictionary setValue:[resultSet stringForColumn:@"superTaskIdentifier"] forKey:@"superTaskIdentifier"];
            [fileModels addObject:[ZXLFileInfoModel dictionary:fileDictionary]];
        }
    }];
    return fileModels;
}
@end
