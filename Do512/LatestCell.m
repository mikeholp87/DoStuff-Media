//
//  VenueCell.m
//  Do512
//
//  Created by Michael Holp on 2/15/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "LatestCell.h"

@implementation LatestCell
@synthesize icon, background, titleLbl;

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
