//
//  HLCustomURLSchemeHandler.m
//  FastWebView
//
//  Created by Sea on 2020/12/4.
//

#import "HLCustomURLSchemeHandler.h"

#import "YYCategories.h"

#import "SDWebImageManager.h"

#import <MobileCoreServices/MobileCoreServices.h>

NSString * const kWKWebViewReuseScheme = @"QLScheme";

@interface HLCustomURLSchemeHandler ()

@property (nonatomic, copy) NSString *replacedStr;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, assign) NSTimeInterval start;

@property (nonatomic, strong) NSDictionary *taskVaildDic;

@end

@implementation HLCustomURLSchemeHandler

- (instancetype)init {
    if (self = [super init]) {
        self.serialQueue = dispatch_queue_create("customURLSchemeHandlerQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

// 最最重要的自定义SDICustomURLSchemeHandler类
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(12.0)){
    
    dispatch_sync(self.serialQueue, ^{
        [self.taskVaildDic setValue:@(YES) forKey:urlSchemeTask.description];
    });
    
    NSDictionary *headers = urlSchemeTask.request.allHTTPHeaderFields;
    NSString *accept      = headers[@"Accept"];
    
    //当前的requestUrl的scheme都是customScheme
    NSString *requestUrl = urlSchemeTask.request.URL.absoluteString;
    NSString *fileName   = [[requestUrl componentsSeparatedByString:@"?"].firstObject componentsSeparatedByString:@"ui-h5/"].lastObject;
    NSString *replacedStr = [requestUrl stringByReplacingOccurrencesOfString:kWKWebViewReuseScheme withString:@"https"];
    self.replacedStr = replacedStr;
    //Intercept and load local resources.
    if ((accept.length >= @"text".length && [accept rangeOfString:@"text/html"].location != NSNotFound)) {//html 拦截
        [self loadLocalFile:fileName urlSchemeTask:urlSchemeTask];
    } else if ([self isMatchingRegularExpressionPattern:@"\\.(js|css)" text:requestUrl]) {//js、css
        [self loadLocalFile:fileName urlSchemeTask:urlSchemeTask];
    } else if (accept.length >= @"image".length && [accept rangeOfString:@"image"].location != NSNotFound) {//image
        
        NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:replacedStr]];
        
        [[SDWebImageManager sharedManager].imageCache queryImageForKey:key
                                                               options:SDWebImageRetryFailed
                                                               context:nil
                                                            completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
            if (image) {
                NSData *imgData    = UIImageJPEGRepresentation(image, 1);
                NSString *mimeType = [self getMimeTypeWithFilePath:fileName] ?:@"image/jpeg";
                
                [self resendRequestWithUrlSchemeTask:urlSchemeTask
                                            mimeType:mimeType
                                         requestData:imgData];
            } else {
                [self loadLocalFile:fileName urlSchemeTask:urlSchemeTask];
            }
        }];
        
    } else {
        //return an empty json.
        NSData *data = [NSJSONSerialization dataWithJSONObject:@{}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
        [self resendRequestWithUrlSchemeTask:urlSchemeTask
                                    mimeType:@"text/html"
                                 requestData:data];
    }
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask  API_AVAILABLE(ios(12.0)){
    NSError *error = [NSError errorWithDomain:urlSchemeTask.request.URL.absoluteString
                                         code:0
                                     userInfo:NULL];
    NSLog(@"weberror:%@",error);
    dispatch_sync(self.serialQueue, ^{
        [self.taskVaildDic setValue:@(NO) forKey:urlSchemeTask.description];
    });
}


- (BOOL)isMatchingRegularExpressionPattern:(NSString *)pattern text:(NSString *)text {
    
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSTextCheckingResult *result = [regex firstMatchInString:text
                                                     options:0
                                                       range:NSMakeRange(0, [text length])];
    
    if (result) {
        return YES;
    }
    
    return NO;
}

//Load local resources, eg: html、js、css...
- (void)loadLocalFile:(NSString *)fileName
        urlSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)) {
    
    if(![self.taskVaildDic boolValueForKey:urlSchemeTask.description default:NO] ||
       !urlSchemeTask ||
       fileName.length == 0) {
        return;
    }
    
    NSString * docsdir    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * H5FilePath = [[docsdir stringByAppendingPathComponent:@"H5"] stringByAppendingPathComponent:@"h5"];
    //If the resource do not exist, re-send request by replacing to http(s).
    NSString *filePath    = [H5FilePath stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"开始重新发送网络请求");
        if ([self.replacedStr hasPrefix:kWKWebViewReuseScheme]) {
            
            self.replacedStr =[self.replacedStr stringByReplacingOccurrencesOfString:kWKWebViewReuseScheme withString:@"https"];
            
            NSLog(@"请求地址:%@",self.replacedStr);
            
        }
        
        self.replacedStr = [NSString stringWithFormat:@"%@?%@",self.replacedStr,@"H5-Version-exits"?@"H5-Version":@""];
        self.start       = CACurrentMediaTime();//开始加载时间
        
        NSLog(@"web请求开始地址:%@",self.replacedStr);
        
        __weak typeof(self)weakSelf  = self;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.replacedStr]];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration
                                                                        defaultSessionConfiguration]];
        
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if([strongSelf.taskVaildDic boolValueForKey:urlSchemeTask.description default:NO] == NO || !urlSchemeTask) {
                return;
            }
            
            [urlSchemeTask didReceiveResponse:response];
            [urlSchemeTask didReceiveData:data];
            
            if (error) {
                [urlSchemeTask didFailWithError:error];
            } else {
                NSTimeInterval delta = CACurrentMediaTime() - strongSelf.start;
                NSLog(@"=======web请求结束地址%@：：：%f", self.replacedStr, delta);
                [urlSchemeTask didFinish];
            }
        }];
        
        [dataTask resume];
        [session finishTasksAndInvalidate];
        
    } else {
        
        NSLog(@"filePath:%@",filePath);
        
        if(![self.taskVaildDic boolValueForKey:urlSchemeTask.description default:NO] ||
           !urlSchemeTask ||
           fileName.length == 0) {
            NSLog(@"return");
            return;
        }
        
        NSData *data = [NSData dataWithContentsOfFile:filePath
                                              options:NSDataReadingMappedIfSafe error:nil];
        
        [self resendRequestWithUrlSchemeTask:urlSchemeTask
                                    mimeType:[self getMimeTypeWithFilePath:filePath]
                                 requestData:data];
    }
}

- (void)resendRequestWithUrlSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
                              mimeType:(NSString *)mimeType
                           requestData:(NSData *)requestData API_AVAILABLE(ios(11.0)) {
    
    if(![self.taskVaildDic boolValueForKey:urlSchemeTask.description default:NO] ||
       !urlSchemeTask ||
       !urlSchemeTask.request ||
       !urlSchemeTask.request.URL) {
        return;
    }
    
    NSString *mimeType_local = mimeType ? mimeType : @"text/html";
    NSData *data = requestData ? requestData : [NSData data];
    
    NSURLResponse *response  = [[NSURLResponse alloc] initWithURL:urlSchemeTask.request.URL
                                                         MIMEType:mimeType_local
                                            expectedContentLength:data.length
                                                 textEncodingName:nil];
    [urlSchemeTask didReceiveResponse:response];
    [urlSchemeTask didReceiveData:data];
    [urlSchemeTask didFinish];
}

//根据路径获取MIMEType
- (NSString *)getMimeTypeWithFilePath:(NSString *)filePath {
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[filePath pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    
    //The UTI can be converted to a mime type:
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL)
        CFRelease(type);
    
    return mimeType;
}


@end
