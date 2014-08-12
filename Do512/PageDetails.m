//
//  WebDisplay.m
//  Do512
//
//  Created by Michael Holp on 1/19/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "PageDetails.h"
#import "SWRevealViewController.h"
#import "MBProgressHUD.h"
#import "WebDisplay.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface PageDetails() {
    NSURLConnection *connection;
    NSMutableURLRequest *requestObj;
    NSMutableData *buffer;
    NSDictionary *siteinfo;
    UIWebView *webView;
}

@end

@implementation PageDetails
@synthesize titleView, venueLbl, facebookBtn, tagBtn, websiteBtn, facebookIcon, markerIcon, tagIcon, websiteIcon, twitterBtn, twitterIcon, starsIcon, votesIcon, presentedLbl, votesLbl, priceLbl, dateLbl, timeLbl, starsLbl, addBtn, buyBtn, rsvpBtn, winBtn, background, icon, type;

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
    
    UIView *logoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"]) logo.image = [UIImage imageNamed:@"do512_sxsw.png"];
    else logo.image = [UIImage imageNamed:[NSString stringWithFormat:@"do%@.png", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"]]];
    [self.view addSubview:logoView];
    [logoView addSubview:logo];
    self.navigationItem.titleView = logoView;
    
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
    
    _df = [[NSDateFormatter alloc] init];
    
    requestObj = [NSMutableURLRequest requestWithURL:_link];
    connection = [NSURLConnection connectionWithRequest:requestObj delegate:self];
    
    if(connection){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        buffer = [NSMutableData data];
        [connection start];
    }else{
        NSLog(@"Connection Failed");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [buffer setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)thisconn {
    if(thisconn == connection){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            siteinfo = [NSJSONSerialization JSONObjectWithData:buffer options:NSJSONReadingMutableLeaves error:&error];
            
            __block NSString *photo;
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (!error){
                    titleView.text = [siteinfo[type][@"title"] uppercaseString];
                    titleView.textColor = [UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.00 alpha:1];
                    titleView.backgroundColor = [UIColor clearColor];
                    titleView.font = [UIFont boldSystemFontOfSize:25.0];
                    titleView.editable = NO;
                    titleView.scrollEnabled = NO;
                    titleView.showsHorizontalScrollIndicator = NO;
                    titleView.showsVerticalScrollIndicator = NO;
                    
                    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
                        CGSize result = [[UIScreen mainScreen] bounds].size;
                        if (result.height < 500)
                            webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 295, 320, 135)];
                        else
                            webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 295, 320, 220)];
                    }
                    
                    if([type isEqualToString:@"event"] || [type isEqualToString:@"giveaways"]){
                        starsIcon.hidden = NO;
                        votesIcon.hidden = NO;
                        dateLbl.hidden = NO;
                        presentedLbl.hidden = NO;
                        markerIcon.hidden = NO;
                        webView.hidden = NO;
                        
                        presentedLbl.text = [siteinfo[type][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : siteinfo[type][@"presented_by"];
                        venueLbl.text = [siteinfo[type][@"venue"][@"title"] uppercaseString];
                        
                        [webView loadHTMLString:[siteinfo[type][@"description"] isKindOfClass:[NSNull class]] ? @"" : siteinfo[type][@"description"] baseURL:[NSURL URLWithString:@"www.google.com"]];
                        webView.backgroundColor = [UIColor whiteColor];
                        
                        votesLbl.text = [siteinfo[type][@"votes"] stringValue];
                        starsLbl.text = [siteinfo[type][@"allstar_votes"] stringValue];
                        votesLbl.font = [UIFont boldSystemFontOfSize:18.0];
                        starsLbl.font = [UIFont boldSystemFontOfSize:18.0];
                        votesLbl.textColor = [UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.00 alpha:1];
                        starsLbl.textColor = [UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.00 alpha:1];
                        
                        [_df setDateFormat:@"hh:mm a"];
                        timeLbl.text = [_df stringFromDate:[self convertDate]];
                        priceLbl.text = [siteinfo[type][@"ticket_info"] isKindOfClass:[NSNull class]] ? @"" : siteinfo[type][@"ticket_info"];
                        
                        if([siteinfo[type][@"actions"][@"buy"] integerValue] == 1) buyBtn.hidden = NO;
                        [buyBtn addTarget:self action:@selector(showWeb:) forControlEvents:UIControlEventTouchUpInside];
                        [buyBtn setTag:0];
                        photo = @"photo";
                    }else{
                        facebookIcon.hidden = NO;
                        twitterIcon.hidden = NO;
                        twitterBtn.hidden = NO;
                        facebookBtn.hidden = NO;
                        markerIcon.hidden = NO;
                        webView.hidden = NO;
                        
                        if([type isEqualToString:@"venue"]){
                            venueLbl.text = siteinfo[type][@"address"];
                            venueLbl.textColor = [UIColor darkGrayColor];
                        }else{
                            markerIcon.hidden = YES;
                            venueLbl.hidden = YES;
                            tagIcon.hidden = NO;
                            tagBtn.hidden = NO;
                            websiteIcon.hidden = NO;
                            websiteBtn.hidden = NO;
                            [websiteBtn setTitle:siteinfo[type][@"social"][@"home"][@"name"] forState:UIControlStateNormal];
                            [websiteBtn addTarget:self action:@selector(showWeb:) forControlEvents:UIControlEventTouchUpInside];
                            [websiteBtn setTag:3];
                            //[tagBtn setTitle:[siteinfo[type][@"tags"][0][@"tag"] isKindOfClass:[NSNull class]] ? @"" : siteinfo[type][@"tags"][0][@"tag"] forState:UIControlStateNormal];;
                            [tagBtn addTarget:self action:@selector(showWeb:) forControlEvents:UIControlEventTouchUpInside];
                            [tagBtn setTag:4];
                            
                        }
                        
                        [webView loadHTMLString:[siteinfo[type][@"description"] isKindOfClass:[NSNull class]] ? @"" : siteinfo[type][@"description"] baseURL:[NSURL URLWithString:@"www.google.com"]];
                        webView.backgroundColor = [UIColor whiteColor];
                        
                        [facebookBtn setTitle:siteinfo[type][@"social"][@"facebook"][@"name"] == nil ? @"N/A" : siteinfo[type][@"social"][@"facebook"][@"name"] forState:UIControlStateNormal];
                        if(![facebookBtn.titleLabel.text isEqualToString:@"N/A"]){
                            [facebookBtn addTarget:self action:@selector(showWeb:) forControlEvents:UIControlEventTouchUpInside];
                            [facebookBtn setTag:1];
                        }
                        [twitterBtn setTitle:siteinfo[type][@"social"][@"twitter"][@"name"] == nil ? @"N/A" : [NSString stringWithFormat:@"@%@",siteinfo[type][@"social"][@"twitter"][@"name"]] forState:UIControlStateNormal];
                        if(![twitterBtn.titleLabel.text isEqualToString:@"N/A"]){
                            [twitterBtn addTarget:self action:@selector(showWeb:) forControlEvents:UIControlEventTouchUpInside];
                            [twitterBtn setTag:2];
                        }
                        photo = @"default";
                    }
                    
                    [self.view addSubview:webView];
                    
                    [background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",siteinfo[type][@"imagery"][photo]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
                    background.contentMode = UIViewContentModeScaleAspectFit;
                }else
                    NSLog(@"%@",[error localizedDescription]);
            });
        });
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@",[error localizedDescription]);
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)showWeb:(UIButton *)sender
{
    WebDisplay *web = [self.storyboard instantiateViewControllerWithIdentifier:@"WebDisplay"];
    web.title = siteinfo[type][@"title"];
    if(sender.tag == 0) web.link = [NSURL URLWithString:siteinfo[type][@"buy_url"]];
    else if(sender.tag == 1) web.link = [NSURL URLWithString:siteinfo[type][@"social"][@"facebook"][@"url"]];
    else if(sender.tag == 2) web.link = [NSURL URLWithString:siteinfo[type][@"social"][@"twitter"][@"url"]];
    else if(sender.tag == 3) web.link = [NSURL URLWithString:siteinfo[type][@"social"][@"home"][@"url"]];
    else web.link = [NSURL URLWithString:siteinfo[type][@"tags"][0][@"permalink"]];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"sidebar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController pushViewController:web animated:YES];
}

- (NSDate *)convertDate {
    NSArray *array = [siteinfo[type][@"begin_time"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    NSString *begin_date = [NSString stringWithFormat:@"%@-%@-%@ %@",array[0],array[1],array[2],array[3]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [df dateFromString:begin_date];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:NO];
}

@end
