# ZXLUpload
背景:
由于公司做的App 对于文件上传数量控制在100，而且一部分功能不是同步等待上传结果的。
视频要压缩为.mp4 ，时间不能为5分钟。(相信很多人看到这个背景就头大了，100个文件什么鬼)
还是自己慢慢分析实现吧。

功能分析

1.等待多文件上传任务成功进行下一步操作。（等待上传成功再操作其他的功能）

2.不等待多文件上传任务成功继续操作其他的功能。（不等上传结果操作其他功能）

3.与非多文件任务上传同时存在。（这个任务实现要与单个文件上传方式同在）

4.断网后所有上传任务中断,恢复网络后所有任务继续。

5.App突然被干掉重启继续中断的上传任务。

6.上传成功过的文件不重复上传，减少流量损耗、提高上传速度、提高上传成功率。

7.不同任务中有相同文件正在上传等待上传结果，同步上传进度、文件信息。（如果有需要视频压缩同理）

8.有视频压缩的控制同时存在的压缩数量。

9.文件上传控制同时存在的上传数量。（目前我用的阿里云上传库里面解决了此问题）

10.控制内存、CPU等性能。

暂时就分析到这里吧

实现思路

1.准备工作

1.1、文件上传实现，（ZXLAliOSSManager）
公司目前服务器都在阿里云上所以上传也用的阿里云，我只是简单的实现了一个上传封装。

1.2、文件信息model 、任务信息model。（ZXLFileInfoModel、ZXLTaskInfoModel）

1.3、文件处理工具（ZXLFileUtils）、图片处理工具（ZXLPhotosUtils）、视频处理工具（ZXLVideoUtils）、存储管理包括沙盒和数据库（ZXLDocumentUtils和ZXLUploadFmdb）。

1.4、上传结果增、删、改、查。（ZXLUploadFileResultCenter）

1.5、网络环境和状态监控。（ZXLReachability、ZXLNetworkManager）

2.实现过程

2.1、上传管理中心。（ZXLUploadFileManager）

处理任务文件上传和非任务文件上传。

2.2、上传任务管理中心。（ZXLUploadTaskManager）

3.线程安全考虑，针对数组（ZXLSyncMutableArray）、字典（ZXLSyncMutableDictionary）等做线程安全。

4.性能考虑。

4.1、压缩性能考虑。（ZXLCompressManager、ZXLCompressOperation）

4.2、上传性能考虑。（阿里云上传库里面解决了此问题、如果用的是七牛的库可以参考压缩新能考虑的做上传处理）


# 对于ZXLUpload的使用

创建文件模型
1.1 创建相册文件模型 ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithAsset:asset];

1.2 创建拍摄的图片

如果图片不大或者编辑过的图片

ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithImage:image];

拍摄的原图（内部对图片做了处理）

ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithUIImagePickerControllerImage:image];

1.3创建拍摄的视频或者路径文件

ZXLFileInfoModel *model = [[ZXLFileInfoModel alloc] initWithFileURL:filePath];

文件上传 2.1 等待上传结果
[JLBAsyncUploadTaskManager startUploadForIdentifier:self.uploadIdentifier       complete:^(ZXLTaskInfoModel *taskInfo) {
if (taskInfo) {
[self submitFinishWithTaskInfo:taskInfo];
}
}];
2.2 统一处理上传结果

[[ZXLUploadTaskManager manager]  startUploadWithUnifiedResponeseForIdentifier:self.uploadIdentifier];

//处理中心在Dome ZXLUploadUnifiedResponese+Exension 文件中
-(void)extensionUnifiedResponese:(ZXLTaskInfoModel *)taskInfo
函数中

如果有什么疑问留言 或者邮件 244061043@qq.com
