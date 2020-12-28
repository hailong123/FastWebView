//
//  HLDownLoadManager.m
//  FastWebView
//
//  Created by Sea on 2020/12/4.
//

#import "HLDownLoadManager.h"

#import "AFNetworking.h"

#import <SSZipArchive.h>

@interface HLDownLoadManager ()

/// 记录开始下载时间
@property (nonatomic, assign) NSTimeInterval start;

@end

@implementation HLDownLoadManager

- (void)downloadH5ReourcesWithURLString:(NSString *)urlString {
    
    /* 创建网络下载对象 */
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    /* 下载地址 */
    NSURL *url            = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    /* 下载路径 */
    //获取Document文件
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * zipFilePath = [docsdir stringByAppendingPathComponent:@"zip"];//将需要创建的串拼接到后面
    NSString * H5FilePath  = [docsdir stringByAppendingPathComponent:@"H5"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL zipIsDir = NO;
    BOOL H5IsDir  = NO;
    
    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL zipexisted = [fileManager fileExistsAtPath:zipFilePath isDirectory:&zipIsDir];
    BOOL H5Existed  = [fileManager fileExistsAtPath:H5FilePath isDirectory:&H5IsDir];
    
    if ( !(zipIsDir == YES && zipexisted == YES) ) {//如果文件夹不存在 创建压缩包文件目录
        [fileManager createDirectoryAtPath:zipFilePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    if (!(H5IsDir == YES && H5Existed == YES) ) { //如果不存在 创建H5文件目录
        [fileManager createDirectoryAtPath:H5FilePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    
    //删除
    //[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
    NSString *filePath = [zipFilePath stringByAppendingPathComponent:url.lastPathComponent];
    
    /* 开始请求下载 */
    //记录开始下载时间
    self.start = CACurrentMediaTime();
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request
                                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"下载进度：%.0f％", downloadProgress.fractionCompleted * 100);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        /* 设定下载到的位置 */
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        NSTimeInterval delta = CACurrentMediaTime() - self.start;
        
        NSLog(@"下载完成，耗时：%f",delta);
        // filePath就是你下载文件的位置，你可以解压，也可以直接拿来使用
        NSString *imgFilePath = [filePath path];// 将NSURL转成NSString
        NSString *zipPath     = imgFilePath;
        //删除
        //[[NSFileManager defaultManager] removeItemAtPath:H5FilePath error:nil];
        [fileManager createDirectoryAtPath:H5FilePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
        //解压
        [SSZipArchive unzipFileAtPath:zipPath toDestination:H5FilePath];
        //清理缓存
       //[DLCommenHelper clearWebCache];
    }];
    
    [downloadTask resume];
}

@end
