//
//  HLWKWebViewController.m
//  FastWebView
//
//  Created by Sea on 2020/12/2.
//

#import "HLWKWebViewController.h"

#import "HLCustomURLSchemeHandler.h"

#import <WebKit/WebKit.h>

@interface HLWKWebViewController ()
<
    WKUIDelegate,
    WKNavigationDelegate
>

@property (nonatomic, strong) WKWebView * webView;

@end

@implementation HLWKWebViewController

#pragma mark - Cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self config];
    
    [self loadData];
}

#pragma mark - PrivateMethod
- (void)config {
    
    [self.view addSubview:self.webView];
    
    self.webView.frame = self.view.bounds;
}

- (void)loadData {
    //
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"QLScheme://h5.look.163.com/st/november?full_screen=true&status_bar_type=light&keep_status_bar=true&fillbackground=true&userid=10440591&ud=436F1CBF64FDDE754AD346098A5FEA57"]];
    
    [self.webView loadRequest:request];
}

#pragma mark - PublishMethod

#pragma mark - Delegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation
      withError:(NSError *)error {
    
}

#pragma mark - Setter-Getter
- (WKWebView *)webView {
    if (!_webView) {
        
        WKUserContentController *userContentController = WKUserContentController.new;
        WKWebViewConfiguration *configuration          = [[WKWebViewConfiguration alloc] init];
        
        NSString *cookieSource     = [NSString stringWithFormat:@"document.cookie = 'API_SESSION=%@';",@"userToken"];
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:cookieSource
                                                            injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                         forMainFrameOnly:NO];
        [userContentController addUserScript:cookieScript];
        
        // 赋值userContentController
        configuration.userContentController          = userContentController;
        configuration.preferences.javaScriptEnabled  = YES;
        configuration.suppressesIncrementalRendering = YES; // 是否支持记忆读取
        [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];//支持跨域
        
        if (@available(iOS 12.0, *)) {
            [configuration setURLSchemeHandler:[[HLCustomURLSchemeHandler alloc] init] forURLScheme:kWKWebViewReuseScheme];
        } else {
            // Fallback on earlier versions
        }
        
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        _webView                        = [[WKWebView alloc] initWithFrame:CGRectZero
                                                             configuration:configuration];
        _webView.UIDelegate         = self;
        _webView.navigationDelegate = self;
    }
    return _webView;
}

@end
