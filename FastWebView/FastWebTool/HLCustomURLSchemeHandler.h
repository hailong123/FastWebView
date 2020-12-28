//
//  HLCustomURLSchemeHandler.h
//  FastWebView
//
//  Created by Sea on 2020/12/4.
//

#import <Foundation/Foundation.h>

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString * const kWKWebViewReuseScheme;

@interface HLCustomURLSchemeHandler : NSObject <WKURLSchemeHandler>

@end

NS_ASSUME_NONNULL_END
