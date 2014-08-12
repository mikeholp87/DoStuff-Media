//
//  ArtistCell.h
//  Do512
//
//  Created by Michael Holp on 2/12/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GiveawayCell : UITableViewCell
 
@property (nonatomic, retain) IBOutlet UILabel *eventLbl;
@property (nonatomic, retain) IBOutlet UILabel *presentLbl;
@property (nonatomic, retain) IBOutlet UILabel *venueLbl;
@property (nonatomic, retain) IBOutlet UILabel *timeLbl;
@property (nonatomic, retain) IBOutlet UILabel *voteLbl;
@property (nonatomic, retain) IBOutlet UILabel *starsLbl;

@property (nonatomic, retain) IBOutlet UIImageView *starsIcon;
@property (nonatomic, retain) IBOutlet UIImageView *fansIcon;

@property (nonatomic, retain) IBOutlet UIImageView *background;

@end
