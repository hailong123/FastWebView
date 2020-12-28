//
//  HLDownLoadManager.h
//  FastWebView
//
//  Created by Sea on 2020/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HLDownLoadManager : NSObject

/// 下载H5资源包
/// @param urlString CDN 资源地址路径
- (void)downloadH5ReourcesWithURLString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
