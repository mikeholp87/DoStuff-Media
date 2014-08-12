//
//  WebDisplay.m
//  Do512
//
//  Created by Michael Holp on 1/19/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "WebDisplay.h"
#import "SWRevealViewController.h"
#import "MBProgressHUD.h"

@implementation WebDisplay
@synthesize type;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @"";
    
    UIView *logoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"]) logo.image = [UIImage imageNamed:@"do512_sxsw.png"];
    else logo.image = [UIImage imageNamed:[NSString stringWithFormat:@"do%@.png", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"]]];
    [self.view addSubview:logoView];
    [logoView addSubview:logo];
    self.navigationItem.titleView = logoView;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.tabBarController.tabBar.hidden = YES;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *btnImg;
    if([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
        btnImg = [UIImage imageNamed:@"ds-nav-back_red.png"];
    else
        btnImg = [UIImage imageNamed:@"ds-nav-back_white.png"];
    [btn setImage:btnImg forState:UIControlStateNormal];
    btn.frame = CGRectMake(0, 0, btnImg.size.width, btnImg.size.height);
    [btn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"sidebar"]){
        self.navigationController.tabBarController.tabBar.hidden = YES;
        _link = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:@"urlString"]];
    }
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height)];
    _webView.delegate = self;
    [self.view addSubview:_webView];
    [_webView scalesPageToFit];
    [_webView loadRequest:[NSURLRequest requestWithURL:_link]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.tabBarController.tabBar.hidden = NO;
}

- (void)goBack
{
    if([type isEqualToString:@"latest"]) [self.navigationController popToRootViewControllerAnimated:YES];
    else [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
}

@end
