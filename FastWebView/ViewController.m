//
//  ViewController.m
//  FastWebView
//
//  Created by Sea on 2020/12/2.
//

#import "ViewController.h"

#import "HLWKWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - Cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self config];
}

#pragma mark - PrivateMethod
- (void)config {
    self.view.backgroundColor = [UIColor redColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    HLWKWebViewController *webView = [[HLWKWebViewController alloc] init];
    
    [self presentViewController:webView animated:YES completion:nil];
}

@end
