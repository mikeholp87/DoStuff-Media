//
//  ArtistsTable.m
//  Do512
//
//  Created by Michael Holp on 2/12/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "GiveawayTable.h"
#import "JSONReader.h"
#import "PageDetails.h"
#import "MBProgressHUD.h"
#import "GiveawayCell.h"
#import "SWRevealViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "MenuNavigation.h"

@interface GiveawayTable () {
    MenuNavigation *menuNav;
    UISegmentedControl *segControl;
    NSMutableData *buffer;
    NSURLConnection *connection;
    NSUInteger page;
}
@end

@implementation GiveawayTable
@synthesize searchDisplayController, searchBar;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Giveaways"];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"Events"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _df = [[NSDateFormatter alloc] init];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"page"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    page = [[NSUserDefaults standardUserDefaults] integerForKey:@"page"];
    
    [self setupView];
    
    [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"giveaways", @"mode":@"upcoming"}];
    _giveaway = [[JSONReader sharedInstance] getPlist:@"giveaways"];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reload) userInfo:nil repeats:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Giveaways"];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"Events"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"DSReloadDataNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMenu) name:@"DSShowMenuNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMenu) name:@"DSHideMenuNotification" object:nil];
    [self addObserver:self forKeyPath:@"self.tabBarController.selectedViewController" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSHideMenuNotification" object:self userInfo:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupView
{
    UIBarButtonItem *revealButtonItem;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"] style:UIBarButtonItemStyleBordered target:self.revealViewController action:@selector(revealToggle:)];
    else
        revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon@2x.png"] style:UIBarButtonItemStyleBordered target:self.revealViewController action:@selector(revealToggle:)];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:@"bkg_image"]]]] forBarMetrics:UIBarMetricsDefault];
    
    UIView *logoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"]) logo.image = [UIImage imageNamed:@"do512_sxsw.png"];
    else logo.image = [UIImage imageNamed:[NSString stringWithFormat:@"do%@.png", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"]]];
    [self.view addSubview:logoView];
    [logoView addSubview:logo];
    self.navigationItem.titleView = logoView;
    
    UIBarButtonItem *searchBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ds-nav-search_gray.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showSearchBar)];
    searchBtn.tintColor = [UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.00 alpha:1];
    self.navigationItem.rightBarButtonItem = searchBtn;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.00 alpha:1];
    [refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    menuNav = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuNavigation"];
    [menuNav willMoveToParentViewController:self];
    menuNav.view.frame = CGRectMake(0, 0, 320, 40);
    [self.view addSubview:menuNav.view];
    [self addChildViewController:menuNav];
    [menuNav didMoveToParentViewController:self];
    
    segControl = [[UISegmentedControl alloc] initWithItems:@[[UIImage imageNamed:@"ds-nav-list_gray.png"], [UIImage imageNamed:@"ds-nav-map_gray.png"]]];
    segControl.frame = CGRectMake(245, 8, 70, 30);
    [segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segControl addTarget:self action:@selector(chooseSegment:) forControlEvents:(UIControlEventValueChanged)];
    [segControl setEnabled:NO forSegmentAtIndex:0];
    [segControl setTintColor:[UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.0 alpha:1]];
    segControl.momentary = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchDisplayController.searchResultsTableView.backgroundColor = [UIColor clearColor];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.searchDisplayController.searchResultsTableView)
        return 1;
    else
        return [_giveaway[@"event_groups"][section][@"events"] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults[@"search_results"][@"results"] count];
    else
        return [_giveaway[@"event_groups"] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:14]];
    [label setTextColor:[UIColor whiteColor]];
    if(tableView == self.searchDisplayController.searchResultsTableView)
        label.text = _searchResults[@"search_results"][@"results"][section][@"begin_date"];
    else
        label.text = (section == 0) ? [NSString stringWithFormat:@"%@\t\t\t\t\t\t\tPage %d", _giveaway[@"event_groups"][section][@"date"], [[NSUserDefaults standardUserDefaults] integerForKey:@"page"]] : [NSString stringWithFormat:@"%@", _giveaway[@"event_groups"][section][@"date"]];
    [view addSubview:label];
    [view setBackgroundColor:[UIColor colorWithRed:46/255.0 green:46/255.0 blue:46/255.0 alpha:1.0]];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GiveawayCell";
    GiveawayCell *cell = (GiveawayCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil){
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"Giveaway" owner:nil options:nil];
        for (id currentObject in topLevelObjects) {
            if ([currentObject isKindOfClass:[UITableViewCell class]]) {
                cell = (GiveawayCell *)currentObject;
                break;
            }
        }
    }
    
    if(tableView == self.searchDisplayController.searchResultsTableView){
        cell.eventLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"title"] isKindOfClass:[NSNull class]] ? @"" : [_searchResults[@"search_results"][@"results"][indexPath.section][@"title"] uppercaseString];
        cell.presentLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : [_searchResults[@"search_results"][@"results"][indexPath.row][@"presented_by"] uppercaseString];
        [_df setDateFormat:@"hh:mm a"];
        cell.timeLbl.text = [_df stringFromDate:[self convertDate:indexPath.section index:indexPath.section search:TRUE]];
        cell.venueLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"venue"][@"title"] isKindOfClass:[NSNull class]] ? @"" : [_searchResults[@"search_results"][@"results"][indexPath.section][@"venue"][@"title"] uppercaseString];
        cell.voteLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"votes"] stringValue];
        cell.starsLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"allstar_votes"] stringValue];
        [cell.background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",_searchResults[@"search_results"][@"results"][indexPath.section][@"imagery"][@"photo"]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }else{
        cell.eventLbl.text = [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"title"] isKindOfClass:[NSNull class]] ? @"" : [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"title"] uppercaseString];
        cell.presentLbl.text = [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"presented_by"] uppercaseString];
        [_df setDateFormat:@"hh:mm a"];
        cell.timeLbl.text = [_df stringFromDate:[self convertDate:indexPath.section index:indexPath.row search:FALSE]];
        cell.venueLbl.text = [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"venue"][@"title"] isKindOfClass:[NSNull class]] ? @"" : [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"venue"][@"title"] uppercaseString];
        cell.voteLbl.text = [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"votes"] stringValue];
        cell.starsLbl.text = [_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"allstar_votes"] stringValue];
        [cell.background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"imagery"][@"photo"]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PageDetails *web = [self.storyboard instantiateViewControllerWithIdentifier:@"PageDetails"];
    web.type = @"event";
    if(tableView == self.searchDisplayController.searchResultsTableView){
        web.title = _searchResults[@"search_results"][@"results"][indexPath.row][@"title"];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"])
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://sx2014.do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_searchResults[@"search_results"][@"results"][indexPath.row][@"permalink"]]];
        else
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_searchResults[@"search_results"][@"results"][indexPath.row][@"permalink"]]];
    }else{
        web.title = _giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"title"];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"])
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://sx2014.do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"permalink"]]];
        else
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_giveaway[@"event_groups"][indexPath.section][@"events"][indexPath.row][@"permalink"]]];
    }
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"sidebar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController pushViewController:web animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 120.0;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(![self.searchDisplayController isActive]){
        NSInteger currentOffset = scrollView.contentOffset.y;
        NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        if (maximumOffset - currentOffset <= -40) {
            [self loadMore];
        }
    }
}

- (void)chooseSegment:(UISegmentedControl *)segment {
    if([segment selectedSegmentIndex] == 0){
        [segControl setEnabled:NO forSegmentAtIndex:0];
        [segControl setEnabled:YES forSegmentAtIndex:1];
    }
    else{
        [segControl setEnabled:YES forSegmentAtIndex:0];
        [segControl setEnabled:NO forSegmentAtIndex:1];
    }
}

- (void)showMenu
{
    menuNav.view.frame = CGRectMake(0, 0, 320, 300);
}

- (void)hideMenu
{
    menuNav.view.frame = CGRectMake(0, 0, 320, 40);
}

#pragma mark - UISearchDisplay Delegate

- (void)showSearchBar
{
    self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top);
    
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    [self.view addSubview:searchBar];
    [searchBar becomeFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.hidden = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://do%@.com/search.json?query=%@&only=events", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], self.searchBar.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    if(connection){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        buffer = [NSMutableData data];
        [connection start];
    }else{
        NSLog(@"Connection Failed");
    }
}

-(void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    controller.active = YES;
    
    [self.view addSubview:controller.searchBar];
    [self.view bringSubviewToFront:controller.searchBar];
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
            _searchResults = [NSJSONSerialization JSONObjectWithData:buffer options:NSJSONReadingMutableLeaves error:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (!error){
                    [self.searchDisplayController.searchResultsTableView reloadData];
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

- (NSDate *)convertDate:(NSInteger)sec index:(NSInteger)idx search:(BOOL)cond {
    NSArray *array;
    if(cond)
        array = [_searchResults[@"search_results"][@"results"][sec][@"begin_time"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    else
        array = [_giveaway[@"event_groups"][sec][@"events"][idx][@"begin_time"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    NSString *begin_date = [NSString stringWithFormat:@"%@-%@-%@ %@",array[0],array[1],array[2],array[3]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [df dateFromString:begin_date];
}

- (void)reload
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    _giveaway = [[JSONReader sharedInstance] getPlist:@"giveaways"];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadMore
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"giveaways",@"mode":@"upcoming",@"page":[@(page+=1) stringValue]}];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSUserDefaults standardUserDefaults] setInteger:page forKey:@"page"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSMutableDictionary *temp = [[JSONReader sharedInstance] getPlist:@"giveaways"];
            _giveaway[@"event_groups"] = temp[@"event_groups"];
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            [self.tableView reloadData];
        });
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self == self.navigationController.topViewController)
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

@end
