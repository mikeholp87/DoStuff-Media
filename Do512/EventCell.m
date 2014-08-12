//
//  EventCell.m
//  Do512
//
//  Created by Michael Holp on 1/19/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "EventCell.h"

@implementation EventCell
@synthesize eventLbl, presentLbl, timeLbl, voteLbl, starsLbl, venueLbl, addBtn, buyBtn, rsvpBtn, winBtn, background;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
