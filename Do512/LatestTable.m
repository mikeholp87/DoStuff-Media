//
//  VenuesTable.m
//  Do512
//
//  Created by Michael Holp on 2/12/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "LatestTable.h"
#import "JSONReader.h"
#import "PageDetails.h"
#import "WebDisplay.h"
#import "MBProgressHUD.h"
#import "SWRevealViewController.h"
#import "LatestCell.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface LatestTable () {
    NSMutableData *buffer;
    NSURLConnection *connection;
    NSUInteger page;
}
@end

@implementation LatestTable
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
    
    [self setupView];
    
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"page"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    page = [[NSUserDefaults standardUserDefaults] integerForKey:@"page"];
    
    [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"latest"}];
    _latest = [[JSONReader sharedInstance] getPlist:@"latest"];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reload) userInfo:nil repeats:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self addObserver:self forKeyPath:@"self.tabBarController.selectedViewController" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
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
        return [_latest[@"grouped_updates"][section][@"updates"] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults[@"search_results"][@"results"] count];
    else
        return [_latest[@"grouped_updates"] count];
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
        label.text = _latest[@"grouped_updates"][section][@"date"];
    [view addSubview:label];
    [tableView sendSubviewToBack:view];
    [view setBackgroundColor:[UIColor colorWithRed:46/255.0 green:46/255.0 blue:46/255.0 alpha:1.0]];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LatestCell";
    LatestCell *cell = (LatestCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil){
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"Latest" owner:nil options:nil];
        for (id currentObject in topLevelObjects) {
            if ([currentObject isKindOfClass:[UITableViewCell class]]) {
                cell = (LatestCell *)currentObject;
                break;
            }
        }
    }
    
    if(tableView == self.searchDisplayController.searchResultsTableView){
        cell.titleLbl.font = [UIFont boldSystemFontOfSize:12.0];
        cell.titleLbl.text = _searchResults[@"search_results"][@"results"][indexPath.section][@"title"];
        [cell.background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",_searchResults[@"search_results"][@"results"][indexPath.section][@"imagery"][@"photo"]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
        cell.background.hidden = NO;
    }else{
        cell.titleLbl.text = [_latest[@"grouped_updates"][indexPath.section][@"updates"][indexPath.row][@"text"] uppercaseString];
        cell.icon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", _latest[@"grouped_updates"][indexPath.section][@"updates"][indexPath.row][@"icon_name"]]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == self.searchDisplayController.searchResultsTableView){
        PageDetails *web = [self.storyboard instantiateViewControllerWithIdentifier:@"PageDetails"];
        web.type = @"event";
        web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], _searchResults[@"search_results"][@"results"][indexPath.row][@"permalink"]]];
        [self.navigationController pushViewController:web animated:NO];
    }else{
        WebDisplay *web = [self.storyboard instantiateViewControllerWithIdentifier:@"WebDisplay"];
        web.title = _latest[@"grouped_updates"][indexPath.section][@"updates"][indexPath.row][@"text"];
        web.type = @"latest";
        web.link = [NSURL URLWithString:_latest[@"grouped_updates"][indexPath.section][@"updates"][indexPath.row][@"url"]];
        [self.navigationController pushViewController:web animated:NO];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"sidebar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 59.0;
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
            
            NSLog(@"%@", _searchResults);
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

- (void)reload
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    _latest = [[JSONReader sharedInstance] getPlist:@"latest"];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadMore
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"latest",@"page":[@(page+=1) stringValue]}];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSUserDefaults standardUserDefaults] setInteger:page forKey:@"page"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSMutableDictionary *temp = [[JSONReader sharedInstance] getPlist:@"latest"];
            _latest[@"grouped_updates"] = temp[@"grouped_updates"];
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
