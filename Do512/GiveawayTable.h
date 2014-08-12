//
//  ArtistsTable.h
//  Do512
//
//  Created by Michael Holp on 2/12/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GiveawayTable : UITableViewController<UISearchBarDelegate, UISearchDisplayDelegate, NSURLConnectionDelegate>

@property(nonatomic,retain) UISearchBar *searchBar;
@property(nonatomic,retain) UISearchDisplayController *searchDisplayController;
@property(nonatomic,retain) NSMutableDictionary *giveaway;
@property(nonatomic,retain) NSDictionary *searchResults;
@property(nonatomic,retain) NSDateFormatter *df;

@end
