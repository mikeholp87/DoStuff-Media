//
//  WebDisplay.h
//  Do512
//
//  Created by Michael Holp on 1/19/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebDisplay : UIViewController<UIAlertViewDelegate, UIWebViewDelegate>

@property(nonatomic,retain) UIActivityIndicatorView *activityIndicator;
@property(nonatomic,retain) NSURL *link;
@property(assign) NSString *type;
@property(nonatomic,retain) UIWebView *webView;
@property(assign) BOOL sidebar;

@end
