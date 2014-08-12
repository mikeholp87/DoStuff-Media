//
//  WebDisplay.h
//  Do512
//
//  Created by Michael Holp on 1/19/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageDetails : UIViewController<NSURLConnectionDelegate, UIWebViewDelegate>

@property(nonatomic,retain) IBOutlet UITextView *titleView;
@property(nonatomic,retain) IBOutlet UILabel *venueLbl;

@property(nonatomic,retain) IBOutlet UILabel *presentedLbl;
@property(nonatomic,retain) IBOutlet UILabel *dateLbl;
@property(nonatomic,retain) IBOutlet UILabel *timeLbl;
@property(nonatomic,retain) IBOutlet UILabel *starsLbl;
@property(nonatomic,retain) IBOutlet UILabel *votesLbl;
@property(nonatomic,retain) IBOutlet UILabel *priceLbl;

@property(nonatomic,retain) IBOutlet UIButton *twitterBtn;
@property(nonatomic,retain) IBOutlet UIButton *facebookBtn;
@property(nonatomic,retain) IBOutlet UIButton *websiteBtn;
@property(nonatomic,retain) IBOutlet UIButton *tagBtn;
@property(nonatomic,retain) IBOutlet UIButton *buyBtn;
@property(nonatomic,retain) IBOutlet UIButton *winBtn;
@property(nonatomic,retain) IBOutlet UIButton *addBtn;
@property(nonatomic,retain) IBOutlet UIButton *rsvpBtn;

@property(nonatomic,retain) IBOutlet UIImageView *facebookIcon;
@property(nonatomic,retain) IBOutlet UIImageView *twitterIcon;
@property(nonatomic,retain) IBOutlet UIImageView *websiteIcon;
@property(nonatomic,retain) IBOutlet UIImageView *tagIcon;
@property(nonatomic,retain) IBOutlet UIImageView *markerIcon;
@property(nonatomic,retain) IBOutlet UIImageView *starsIcon;
@property(nonatomic,retain) IBOutlet UIImageView *votesIcon;
@property(nonatomic,retain) IBOutlet UIImageView *background;
@property(nonatomic,retain) IBOutlet UIImageView *icon;

@property(nonatomic,retain) NSDateFormatter *df;

@property(nonatomic,retain) NSURL *link;
@property(assign) NSString *type;
@property(assign) BOOL sidebar;

@end
