//
//  VenuesTable.h
//  Do512
//
//  Created by Michael Holp on 2/12/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJsonParser.h"

@interface LatestTable : UITableViewController<UISearchBarDelegate, UISearchDisplayDelegate, UIScrollViewDelegate, NSURLConnectionDelegate>

@property(nonatomic,retain) UISearchDisplayController *searchDisplayController;
@property(nonatomic,retain) NSMutableDictionary *latest;
@property(nonatomic,retain) NSDictionary *searchResults;
@property(nonatomic,retain) UISearchBar *searchBar;

@end
