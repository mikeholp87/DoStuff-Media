//
//  EventsTable.m
//  Do512
//
//  Created by Michael Holp on 2/11/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "EventsTable.h"
#import "EventCell.h"
#import "PageDetails.h"
#import "MapPoint.h"
#import "JSONReader.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "MenuNavigation.h"

@interface EventsTable () {
    MenuNavigation *menuNav;
    UIView *bgView, *infoView;
    UILabel *presentLbl, *timeLbl, *voteLbl, *starLbl, *menuLbl;
    UITextView *titleView, *venueView;
    UIImageView *mapImg, *starsImg, *votesImg;
    UISegmentedControl *segControl;
    NSMutableArray *dataSource;
    NSMutableData *buffer;
    NSURLConnection *connection;
    NSIndexPath *pathLastRow;
    NSUInteger page;
}
@end

@implementation EventsTable
@synthesize searchBar, searchDisplayController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Events"];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"Giveaways"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _df = [[NSDateFormatter alloc] init];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"page"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    page = [[NSUserDefaults standardUserDefaults] integerForKey:@"page"];
    
    [self setupView];
    [self setUserLocation];
    [self reachabilityCheck];
}

- (void)setupView
{
    UIBarButtonItem *revealButtonItem;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"] style:UIBarButtonItemStyleBordered target:self.revealViewController action:@selector(revealToggle:)];
    else
        revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon@2x.png"] style:UIBarButtonItemStyleBordered target:self.revealViewController action:@selector(revealToggle:)];
    
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
    segControl.frame = CGRectMake(235, 2, 80, 40);
    [segControl addTarget:self action:@selector(chooseSegment:) forControlEvents:(UIControlEventValueChanged)];
    [segControl setEnabled:NO forSegmentAtIndex:0];
    [segControl setTintColor:[UIColor colorWithRed:206/255.0 green:46/255.0 blue:48/255.0 alpha:1]];
    segControl.momentary = YES;
    [self.view addSubview:segControl];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchDisplayController.searchResultsTableView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Events"];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"Giveaways"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"DSReloadDataNotification" object:nil];
    [self addObserver:self forKeyPath:@"self.tabBarController.selectedViewController" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMenu) name:@"DSShowMenuNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMenu) name:@"DSHideMenuNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSHideMenuNotification" object:self userInfo:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.searchDisplayController.searchResultsTableView)
        return 1;
    else
        if([_grouped isEqualToString:@"event_groups"])
            return [_events[_grouped][section][@"events"] count];
        else
            return [_events[@"events"] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults[@"search_results"][@"results"] count];
    else if([_grouped isEqualToString:@"event_groups"])
        return [_events[_grouped] count];
    else
        return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    UILabel *sectionLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, self.tableView.frame.size.width, 18)];
    [sectionLbl setFont:[UIFont boldSystemFontOfSize:14]];
    [sectionLbl setTextColor:[UIColor whiteColor]];
    [_df setDateFormat:@"MMM dd"];
    if(tableView == self.searchDisplayController.searchResultsTableView)
        sectionLbl.text = _searchResults[@"search_results"][@"results"][section][@"begin_date"];
    else{
        if([_grouped isEqualToString:@"event_groups"]){
            sectionLbl.text = (section == 0) ? [NSString stringWithFormat:@"%@\t\t\t\t\t\t\t\tPage %d", [_df stringFromDate:[self convertDate:section index:0 search:FALSE]], [[NSUserDefaults standardUserDefaults] integerForKey:@"page"]] : [NSString stringWithFormat:@"%@", [_df stringFromDate:[self convertDate:section index:0 search:FALSE]]];
        }else
            sectionLbl.text = [NSString stringWithFormat:@"%@\t\t\t\t\t\t\t\tPage %d", [_df stringFromDate:[self convertDate:0]], [[NSUserDefaults standardUserDefaults] integerForKey:@"page"]];
    }
    [view setBackgroundColor:[UIColor colorWithRed:46/255.0 green:46/255.0 blue:46/255.0 alpha:1.0]];
    [view addSubview:sectionLbl];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EventCell";
    EventCell *cell = (EventCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil){
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"Event" owner:nil options:nil];
        for (id currentObject in topLevelObjects) {
            if ([currentObject isKindOfClass:[UITableViewCell class]]) {
                cell = (EventCell *)currentObject;
                break;
            }
        }
    }
    
    if(tableView == searchDisplayController.searchResultsTableView){
        cell.eventLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"title"] uppercaseString];
        cell.presentLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : [_searchResults[@"search_results"][@"results"][indexPath.section][@"presented_by"] uppercaseString];
        [_df setDateFormat:@"hh:mm a"];
        cell.timeLbl.text = [_df stringFromDate:[self convertDate:indexPath.section index:indexPath.section search:TRUE]];
        cell.venueLbl.text = _searchResults[@"search_results"][@"results"][indexPath.section][@"venue"][@"title"];
        cell.voteLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"votes"] stringValue];
        cell.starsLbl.text = [_searchResults[@"search_results"][@"results"][indexPath.section][@"allstar_votes"] stringValue];
        [cell.background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",_searchResults[@"search_results"][@"results"][indexPath.section][@"imagery"][@"photo"]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }else{
        if([_grouped isEqualToString:@"event_groups"]){
            cell.eventLbl.text = [_events[_grouped][indexPath.section][@"events"][indexPath.row][@"title"] uppercaseString];
            cell.presentLbl.text = [_events[_grouped][indexPath.section][@"events"][indexPath.row][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : [_events[_grouped][indexPath.section][@"events"][indexPath.row][@"presented_by"] uppercaseString];
            [_df setDateFormat:@"hh:mm a"];
            cell.timeLbl.text = [_df stringFromDate:[self convertDate:indexPath.section index:indexPath.row search:FALSE]];
            cell.venueLbl.text = _events[_grouped][indexPath.section][@"events"][indexPath.row][@"venue"][@"title"];
            cell.voteLbl.text = [_events[_grouped][indexPath.section][@"events"][indexPath.row][@"votes"] stringValue];
            cell.starsLbl.text = [_events[_grouped][indexPath.section][@"events"][indexPath.row][@"allstar_votes"] stringValue];
            [cell.background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",_events[_grouped][indexPath.section][@"events"][indexPath.row][@"imagery"][@"photo"]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
        }else{
            cell.eventLbl.text = [_events[@"events"][indexPath.row][@"title"] uppercaseString];
            cell.presentLbl.text = [_events[@"events"][indexPath.row][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : [_events[@"events"][indexPath.row][@"presented_by"] uppercaseString];
            [_df setDateFormat:@"hh:mm a"];
            cell.timeLbl.text = [_df stringFromDate:[self convertDate:indexPath.row]];
            cell.venueLbl.text = _events[@"events"][indexPath.row][@"venue"][@"title"];
            cell.voteLbl.text = [_events[@"events"][indexPath.row][@"votes"] stringValue];
            cell.starsLbl.text = [_events[@"events"][indexPath.row][@"allstar_votes"] stringValue];
            [cell.background setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://a3.res.cloudinary.com/dostuff-media/image/upload//c_fill,g_face,b_rgb:090909,h_300,w_864/%@",_events[@"events"][indexPath.row][@"imagery"][@"photo"]]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PageDetails *web = [self.storyboard instantiateViewControllerWithIdentifier:@"PageDetails"];
    web.type = @"event";
    if(tableView == self.searchDisplayController.searchResultsTableView){
        web.title = _searchResults[@"search_results"][@"results"][indexPath.section][@"title"];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"])
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://sx2014.do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_searchResults[@"search_results"][@"results"][indexPath.section][@"permalink"]]];
        else
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_searchResults[@"search_results"][@"results"][indexPath.section][@"permalink"]]];
    }else{
        if([_grouped isEqualToString:@"event_groups"])
            web.title = _events[_grouped][0][@"events"][indexPath.row][@"venue"][@"title"];
        else
            web.title = _events[@"events"][indexPath.row][@"venue"][@"title"];
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"])
            web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://sx2014.do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_events[@"events"][indexPath.row][@"permalink"]]];
        else
            if([_grouped isEqualToString:@"event_groups"])
                web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_events[_grouped][0][@"events"][indexPath.row][@"permalink"]]];
            else
                web.link = [NSURL URLWithString:[NSString stringWithFormat:@"http://do%@.com%@.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"],_events[@"events"][indexPath.row][@"permalink"]]];
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
        self.tableView.hidden = NO;
        _mapView.hidden = YES;
        if(_mapView != nil){
            _mapView = nil;
            _mapView.delegate = nil;
            _mapView.showsUserLocation = NO;
            [_mapView.layer removeAllAnimations];
            [_mapView removeAnnotations:self.mapView.annotations];
            [_mapView removeFromSuperview];
        }
    }
    else{
        [segControl setEnabled:YES forSegmentAtIndex:0];
        [segControl setEnabled:NO forSegmentAtIndex:1];
        _userCoordinate.latitude = 30.25;
        _userCoordinate.longitude = -97.75;
        
        _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height)];
        _mapView.delegate = self;
        MKCoordinateRegion region;
        region.center.latitude = _userCoordinate.latitude;
        region.center.longitude = _userCoordinate.longitude;
        region.span.latitudeDelta = 0.05;
        region.span.longitudeDelta = 0.05;
        region = [_mapView regionThatFits:region];
        [_mapView setRegion:region animated:YES];
        [_mapView bringSubviewToFront:menuNav.view];
        [self.view addSubview:_mapView];
        
        UIButton *dude = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-60, self.view.frame.size.height-240, 50, 50)];
        [dude setImage:[UIImage imageNamed:@"dude.png"] forState:UIControlStateNormal];
        [dude addTarget:self action:@selector(openAppStore) forControlEvents:UIControlEventTouchUpInside];
        [_mapView addSubview:dude];
        
        [self plotLocations];
    }
}

#pragma mark - MapView Delegate

- (void)plotLocations {
    bgView = [[UIView alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height-350, 140, 160)];
    infoView = [[UIView alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height-350, 120, 160)];
    presentLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 135, 25)];
    titleView = [[UITextView alloc] initWithFrame:CGRectMake(0, 25, 135, 50)];
    timeLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, 70, 140, 25)];
    venueView = [[UITextView alloc] initWithFrame:CGRectMake(22, 92, 110, 35)];
    voteLbl = [[UILabel alloc] initWithFrame:CGRectMake(30, 125, 140, 25)];
    starLbl = [[UILabel alloc] initWithFrame:CGRectMake(85, 125, 140, 25)];
    mapImg = [[UIImageView alloc] initWithFrame:CGRectMake(5, 95, 20, 24)];
    starsImg = [[UIImageView alloc] initWithFrame:CGRectMake(60, 125, 20, 22)];
    votesImg = [[UIImageView alloc] initWithFrame:CGRectMake(5, 125, 20, 22)];
    
    for(int i=0; i<[_events[@"events"] count]; i++){
        NSString *title = _events[@"events"][i][@"venue"][@"title"];
        _venueCoordinate.latitude = [_events[@"events"][i][@"venue"][@"latitude"] isKindOfClass:[NSNull class]] ? 0.0 : [_events[@"events"][i][@"venue"][@"latitude"] floatValue];
        _venueCoordinate.longitude = [_events[@"events"][i][@"venue"][@"longitude"] isKindOfClass:[NSNull class]] ? 0.0 : [_events[@"events"][i][@"venue"][@"longitude"] floatValue];
        MapPoint *annotation = [[MapPoint alloc] initWithCoordinate:_venueCoordinate title:title tag:i];
        [_mapView addAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *identifier = @"myAnnotation";
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [mv dequeueReusableAnnotationViewWithIdentifier:identifier];
    if(annotationView == nil){
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        annotationView.canShowCallout = NO;
        UIImage *pinDeselect = [UIImage imageNamed:@"pin_deselect.png"];
        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            annotationView.image = [self drawText:[NSString stringWithFormat:@"%d",[(MapPoint *)annotation tag]] inImage:pinDeselect atPoint:CGPointMake(0, 0)];
        else annotationView.image = pinDeselect;
    }else{
        annotationView.annotation = annotation;
    }
    return annotationView;
}

- (void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views
{
    MKAnnotationView *ulv = [mv viewForAnnotation:mv.userLocation];
    ulv.canShowCallout = NO;
    
    id <MKAnnotation> mp = [mv.annotations objectAtIndex:0];
    [mv selectAnnotation:mp animated:YES];
}

- (void)mapView:(MKMapView *)mv didSelectAnnotationView:(MKAnnotationView *)view
{
    id<MKAnnotation>mp = [mv.annotations objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"previous_pin"]];
    [mv deselectAnnotation:mp animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[(MapPoint *)view.annotation tag] forKey:@"previous_pin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIImage *pinSelect = [UIImage imageNamed:@"pin_select.png"];
    if([(MapPoint *)view.annotation tag]-11 < 0){
        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            view.image = [self drawText:[@([(MapPoint *)view.annotation tag]) stringValue] inImage:pinSelect atPoint:CGPointMake(15, 10)];
        else view.image = pinSelect;
    }else{
        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            view.image = [self drawText:[@([(MapPoint *)view.annotation tag]) stringValue] inImage:pinSelect atPoint:CGPointMake(10, 10)];
        else view.image = pinSelect;
    }
    
    presentLbl.text = [_events[@"events"][[(MapPoint *)view.annotation tag]][@"presented_by"] isKindOfClass:[NSNull class]] ? @"" : _events[@"events"][[(MapPoint *)view.annotation tag]][@"presented_by"];
    presentLbl.textColor = [UIColor lightGrayColor];
    presentLbl.font = [UIFont boldSystemFontOfSize:10.0];
    
    titleView.text = [_events[@"events"][[(MapPoint *)view.annotation tag]][@"title"] isKindOfClass:[NSNull class]] ? @"" : _events[@"events"][[(MapPoint *)view.annotation tag]][@"title"];
    titleView.textColor = [UIColor whiteColor];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.font = [UIFont boldSystemFontOfSize:12.0];
    titleView.editable = NO;
    titleView.scrollEnabled = NO;
    titleView.showsHorizontalScrollIndicator = NO;
    titleView.showsVerticalScrollIndicator = NO;
    
    [_df setDateFormat:@"EEEE M/dd hh:mm a"];
    
    timeLbl.text = [_df stringFromDate:[self convertDate:view.tag]];
    timeLbl.textColor = [UIColor whiteColor];
    timeLbl.font = [UIFont boldSystemFontOfSize:10.0];
    
    venueView.text = [_events[@"events"][[(MapPoint *)view.annotation tag]][@"venue"][@"title"] isKindOfClass:[NSNull class]] ? @"" : _events[@"events"][[(MapPoint *)view.annotation tag]][@"venue"][@"title"];
    venueView.textColor = [UIColor whiteColor];
    venueView.backgroundColor = [UIColor clearColor];
    venueView.font = [UIFont boldSystemFontOfSize:10.0];
    venueView.editable = NO;
    venueView.scrollEnabled = NO;
    venueView.showsHorizontalScrollIndicator = NO;
    venueView.showsVerticalScrollIndicator = NO;
    
    voteLbl.text = [[_events[@"events"][[(MapPoint *)view.annotation tag]][@"votes"] stringValue] isKindOfClass:[NSNull class]] ? @"" : [_events[@"events"][[(MapPoint *)view.annotation tag]][@"votes"] stringValue];
    voteLbl.textColor = [UIColor whiteColor];
    voteLbl.font = [UIFont boldSystemFontOfSize:10.0];
    
    starLbl.text = [[_events[@"events"][[(MapPoint *)view.annotation tag]][@"allstar_votes"] stringValue] isKindOfClass:[NSNull class]] ? @"" : [_events[@"events"][[(MapPoint *)view.annotation tag]][@"allstar_votes"] stringValue];
    starLbl.textColor = [UIColor whiteColor];
    starLbl.font = [UIFont boldSystemFontOfSize:10.0];
    
    mapImg.image = [UIImage imageNamed:@"ds-cell-map.png"];
    starsImg.image = [UIImage imageNamed:@"ds-cell-star.png"];
    votesImg.image = [UIImage imageNamed:@"ds-cell-user.png"];
    
    [infoView addSubview:presentLbl];
    [infoView addSubview:titleView];
    [infoView addSubview:timeLbl];
    [infoView addSubview:venueView];
    [infoView addSubview:voteLbl];
    [infoView addSubview:starLbl];
    [infoView addSubview:mapImg];
    [infoView addSubview:starsImg];
    [infoView addSubview:votesImg];
    
    [bgView setBackgroundColor:[UIColor blackColor]];
    [bgView setAlpha:0.8];
    bgView.layer.cornerRadius = 5.0;
    bgView.layer.masksToBounds = YES;
    [_mapView addSubview:bgView];
    [_mapView addSubview:infoView];
    [bgView bringSubviewToFront:infoView];
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    UIImage *pinDeselect = [UIImage imageNamed:@"pin_deselect.png"];
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        view.image = [self drawText:[@([(MapPoint *)view.annotation tag]) stringValue] inImage:pinDeselect atPoint:CGPointMake(0, 0)];
    else view.image = pinDeselect;
}

#pragma mark - Other Methods

- (NSDate *)convertDate:(NSInteger)index {
    NSArray *array = [_events[@"events"][index][@"begin_time"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    NSString *begin_date = [NSString stringWithFormat:@"%@-%@-%@ %@",array[0],array[1],array[2],array[3]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [df dateFromString:begin_date];
}

- (NSDate *)convertDate:(NSInteger)sec index:(NSInteger)idx search:(BOOL)cond {
    NSArray *array;
    if(cond)
        array = [_searchResults[@"search_results"][@"results"][sec][@"begin_time"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    else
        array = [_events[@"event_groups"][sec][@"events"][idx][@"begin_time"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"T-"]];
    NSString *begin_date = [NSString stringWithFormat:@"%@-%@-%@ %@",array[0],array[1],array[2],array[3]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [df dateFromString:begin_date];
}

- (UIImage *)drawText:(NSString *)text inImage:(UIImage *)image atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor whiteColor] set];
    
    UIFont *font = [UIFont boldSystemFontOfSize:25];
    
    if([text respondsToSelector:@selector(drawInRect:withAttributes:)]){
        NSDictionary *att = @{NSFontAttributeName:font};
        [text drawInRect:rect withAttributes:att];
    }
    else{
        [text drawInRect:CGRectIntegral(rect) withFont:font];
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)sendNotif {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"events",@"day":@"today",@"page":[@([[NSUserDefaults standardUserDefaults] integerForKey:@"page"]) stringValue]}];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"layout"}];
}

- (void)openAppStore
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/us/app/dude-wheres-my-car/id585917773?mt=8"]];
}

- (void)reload
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    _events = [[JSONReader sharedInstance] getPlist:@"events"];
    
    if([_events objectForKey:@"events"] == nil){
        _grouped = @"event_groups";
    }else
        _grouped = @"events";
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadMore
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"events",@"day":@"today",@"page":[@(page+=1) stringValue]}];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSUserDefaults standardUserDefaults] setInteger:page forKey:@"page"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSMutableDictionary *temp = [[JSONReader sharedInstance] getPlist:@"events"];
            _events[@"events"] = temp[@"events"];
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            [self.tableView reloadData];
        });
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self == self.navigationController.topViewController)
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)showWeb:(UIButton *)button
{
    PageDetails *web = [self.storyboard instantiateViewControllerWithIdentifier:@"PageDetails"];
    web.title = _events[@"events"][button.tag][@"venue"][@"title"];
    web.link = [NSURL URLWithString:_events[@"events"][button.tag][@"buy_url"]];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"sidebar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController pushViewController:web animated:YES];
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
        [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
        buffer = [NSMutableData data];
        [connection start];
    }else{
        NSLog(@"Connection Failed");
    }
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
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

#pragma mark - CLLocationManager Delegate

- (void)setUserLocation
{
    _locMgr = [[CLLocationManager alloc] init];
    _locMgr.delegate = self;
    _locMgr.desiredAccuracy = kCLLocationAccuracyBest;
    _locMgr.distanceFilter = kCLDistanceFilterNone;
    [_locMgr startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [_locMgr stopUpdatingLocation];
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        CLLocation *location = [locations objectAtIndex:0];
        _userCoordinate = location.coordinate;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self locationManager:manager didUpdateLocations:@[newLocation]];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status == kCLAuthorizationStatusAuthorized) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(reload) userInfo:nil repeats:NO];
        
        _userCoordinate = _locMgr.location.coordinate;
        
        NSString *city = [[NSUserDefaults standardUserDefaults] objectForKey:@"city"];
        NSLog(@"%@", city);
        
        city = @"Austin";
        
        if([city isEqualToString:@"Austin"]){
            _userCoordinate.latitude = 30.25;
            _userCoordinate.longitude = -97.75;
        }else if([city isEqualToString:@"Boston"]){
            _userCoordinate.latitude = 42.36;
            _userCoordinate.longitude = -71.06;
        }else if([city isEqualToString:@"Chicago"]){
            _userCoordinate.latitude = 41.88;
            _userCoordinate.longitude = -87.63;
        }else if([city isEqualToString:@"Indianapolis"]){
            _userCoordinate.latitude = 39.79;
            _userCoordinate.longitude = -86.15;
        }else if([city isEqualToString:@"Los Angeles"]){
            _userCoordinate.latitude = 34.05;
            _userCoordinate.longitude = -118.25;
        }else if([city isEqualToString:@"Nashville"]){
            _userCoordinate.latitude = 36.17;
            _userCoordinate.longitude = -86.78;
        }else if([city isEqualToString:@"New York City"]){
            _userCoordinate.latitude = 40.67;
            _userCoordinate.longitude = -73.94;
        }else if([city isEqualToString:@"San Francisco"]){
            _userCoordinate.latitude = 37.78;
            _userCoordinate.longitude = -122.42;
        }else if([city isEqualToString:@"St. Louis"]){
            _userCoordinate.latitude = 38.6272;
            _userCoordinate.longitude = -90.1978;
        }
        
        [self fetchAreaCode];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [manager stopUpdatingLocation];
    NSLog(@"error%@",error);
    switch([error code]){
        case kCLErrorNetwork:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please check your network connection or that you are not in airplane mode" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"User has denied to use current Location " delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default: break;
    }
}

- (void)fetchAreaCode
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self fetchReverseGeocodeAddress:_userCoordinate.latitude withLongitude:_userCoordinate.longitude withCompletionHanlder:^(NSString *city, NSString *state){
            if([city isEqualToString:@"Austin"]) _areacode = @"512";
            else if([city isEqualToString:@"Boston"]) _areacode = @"617";
            else if([city isEqualToString:@"Chicago"]) _areacode = @"312";
            else if([city isEqualToString:@"Indianapolis"]) _areacode = @"317";
            else if([city isEqualToString:@"Los Angeles"]) _areacode = @"la";
            else if([city isEqualToString:@"Nashville"]) _areacode = @"615";
            else if([city isEqualToString:@"New York"]) _areacode = @"nyc";
            else if([city isEqualToString:@"San Francisco"]) _areacode = @"415";
            else if([city isEqualToString:@"St Louis"]) _areacode = @"314";
            
            UIView *logoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
            UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"]) logo.image = [UIImage imageNamed:@"do512_sxsw.png"];
            else logo.image = [UIImage imageNamed:[NSString stringWithFormat:@"do%@.png", _areacode]];
            [self.view addSubview:logoView];
            [logoView addSubview:logo];
            self.navigationItem.titleView = logoView;
            
            [[NSUserDefaults standardUserDefaults] setObject:_areacode forKey:@"areacode"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sendNotif) userInfo:nil repeats:NO];
            _events = [[JSONReader sharedInstance] getPlist:@"events"];
            _layout = [[JSONReader sharedInstance] getPlist:@"layout"];
            
            NSString *bkg = [NSString stringWithFormat:@"http://res.cloudinary.com/dostuff-media/image/upload//c_fill,b_rgb:090909,h_123,w_1200/%@",_layout[@"default_images"][@"bkg_3"]];
            [[NSUserDefaults standardUserDefaults] setObject:bkg forKey:@"bkg_image"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:bkg]]] forBarMetrics:UIBarMetricsDefault];
        });
    });
}

- (void)fetchReverseGeocodeAddress:(float)pdblLatitude withLongitude:(float)pdblLongitude withCompletionHanlder:(ReverseGeoCompletionBlock)completion {
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLGeocodeCompletionHandler completionHandler = ^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"Geocode failed with error: %@", error);
            return;
        }
        if (placemarks) {
            [placemarks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CLPlacemark *placemark = placemarks[0];
                NSDictionary *info = placemark.addressDictionary;
                
                NSString *city = [info objectForKey:@"City"];
                NSString *state = [info objectForKey:@"State"];
                
                [[NSUserDefaults standardUserDefaults] setObject:state forKey:@"state"];
                [[NSUserDefaults standardUserDefaults] setObject:city forKey:@"city"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (completion) {
                    completion(city, state);
                }
                *stop = YES;
            }];
        }
    };
    
    CLLocation *newLocation = [[CLLocation alloc]initWithLatitude:pdblLatitude longitude:pdblLongitude];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:completionHandler];
}

-(BOOL)reachabilityCheck
{
    Reachability *wifiReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [wifiReach currentReachabilityStatus];
    switch (netStatus)
    {
        case NotReachable:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wi-fi unreachable" message:@"Internet access is not available." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert setTag:2];
            [alert show];
            NSLog(@"Access Not Available");
            return NO;
        }
        case ReachableViaWWAN:
        {
            NSLog(@"Reachable WWAN");
            return YES;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"Reachable WiFi");
            return YES;
        }
    }
}

@end
