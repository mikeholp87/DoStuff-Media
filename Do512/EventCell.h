//
//  EventCell.h
//  Do512
//
//  Created by Michael Holp on 1/19/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *eventLbl;
@property (nonatomic, retain) IBOutlet UILabel *presentLbl;
@property (nonatomic, retain) IBOutlet UILabel *venueLbl;
@property (nonatomic, retain) IBOutlet UILabel *timeLbl;
@property (nonatomic, retain) IBOutlet UILabel *voteLbl;
@property (nonatomic, retain) IBOutlet UILabel *starsLbl;

@property (nonatomic, retain) IBOutlet UIButton *addBtn;
@property (nonatomic, retain) IBOutlet UIButton *buyBtn;
@property (nonatomic, retain) IBOutlet UIButton *rsvpBtn;
@property (nonatomic, retain) IBOutlet UIButton *winBtn;

@property (nonatomic, retain) IBOutlet UIImageView *background;

@end
