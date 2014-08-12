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

@interface WebDisplay() {
    NSURLConnection *connection;
    NSMutableData *buffer;
    NSDictionary *siteinfo;
    NSDateFormatter *df;
}

@end

@implementation WebDisplay
@synthesize titleLbl, addressLbl, descView, facebookBtn, facebookIcon, twitterBtn, twitterIcon, starsIcon, votesIcon, votesLbl, timeLbl, starsLbl, background, icon, type;

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
    UIButton *logo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    [logo setImage:[UIImage imageNamed:[NSString stringWithFormat:@"do%@.png", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"]]] forState:UIControlStateNormal];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:logoView];
    [logoView addSubview:logo];
    self.navigationItem.titleView = logoView;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSMutableURLRequest *requestObj;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"sidebar"]){
        self.navigationController.tabBarController.tabBar.hidden = YES;
        _link = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:@"urlString"]];
    }
    
    df = [[NSDateFormatter alloc] init];
    
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
                    titleLbl.text = [siteinfo[type][@"title"] uppercaseString];
                    addressLbl.text = siteinfo[type][@"address"];
                    descView.text = [self convertHTML:siteinfo[type][@"description"]];
                    if([type isEqualToString:@"event"]){
                        starsIcon.hidden = NO;
                        votesIcon.hidden = NO;
                        
                        votesLbl.text = siteinfo[type][@"votes"];
                        starsLbl.text = siteinfo[type][@"allstar_votes"];
                        [df setDateFormat:@"hh:mm a"];
                        timeLbl.text = [df stringFromDate:[self convertDate:siteinfo[type][@"begin_time"]]];
                        
                        photo = @"photo";
                    }else{
                        facebookIcon.hidden = NO;
                        twitterIcon.hidden = NO;
                        facebookBtn.titleLabel.text = siteinfo[type][@"social"][@"facebook"][@"url"];
                        twitterBtn.titleLabel.text = siteinfo[type][@"social"][@"twitter"][@"url"];
                        photo = @"default";
                    }
                    background.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",siteinfo[type][@"imagery"][photo]]]]];
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

- (NSDate *)convertDate:(NSString *)begin {
    NSArray *array = [begin componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    NSString *begin_time = [NSString stringWithFormat:@"%@-%@-%@ %@",array[0],array[1],array[2],array[3]];
    
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    return [df dateFromString:begin_time];
}

- (NSString *)convertHTML:(NSString *)html {
    NSScanner *myScanner;
    NSString *text = nil;
    myScanner = [NSScanner scannerWithString:html];
    
    while ([myScanner isAtEnd] == NO) {
        [myScanner scanUpToString:@"<" intoString:NULL] ;
        [myScanner scanUpToString:@">" intoString:&text] ;
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return html;
}

@end
