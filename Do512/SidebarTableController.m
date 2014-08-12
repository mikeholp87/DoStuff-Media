//
//  SidebarTableController.m
//  Dude Where's My Car
//
//  Created by Michael Holp on 2/3/14.
//  Copyright (c) 2014 Phoenix Rising LLC. All rights reserved.
//

#import "SidebarTableController.h"
#import "SWRevealViewController.h"
#import "MBProgressHUD.h"
#import "PageDetails.h"
#import "JSONReader.h"

@interface SidebarTableController () {
    NSDictionary *_featured;
    NSArray *_products, *_menuItems;
    NSURL *web_url;
}

@end

@implementation SidebarTableController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:@{@"type":@"layout"}];
    _featured = [[JSONReader sharedInstance] getPlist:@"layout"];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) return [_featured[@"lenses"] count] + 1;
    else return [_featured[@"featured_links"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0) return @"Menu";
    else return @"Featured Stuff";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if(indexPath.section == 0){
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
        if(indexPath.row == 0){
            cell.textLabel.text = @"Home";
            cell.imageView.image = [UIImage imageNamed:@"home_icon.png"];
        }else{
            cell.textLabel.text = _featured[@"lenses"][0][@"title"];
            cell.imageView.image = [UIImage imageNamed:@"sx_icon.png"];
        }
        cell.detailTextLabel.text = @"";
    }else{
        cell.textLabel.font = [UIFont systemFontOfSize:10.0];
        cell.detailTextLabel.textColor = [UIColor clearColor];
        
        cell.textLabel.text = _featured[@"featured_links"][indexPath.row][@"link_title"];
        cell.detailTextLabel.text = _featured[@"featured_links"][indexPath.row][@"link_url"];
        cell.imageView.image = [UIImage imageNamed:@"ds-table-list.png"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1){
        [[NSUserDefaults standardUserDefaults] setObject:[tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text forKey:@"urlString"];
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"sidebar"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self performSegueWithIdentifier:@"Web" sender:self];
    }else if(indexPath.section == 0 && indexPath.row == 1){
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"SX2014"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self performSegueWithIdentifier:@"Home" sender:self];
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"SX2014"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self performSegueWithIdentifier:@"Home" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UINavigationController *destViewController = (UINavigationController *)segue.destinationViewController;
    destViewController.title = [[_menuItems objectAtIndex:indexPath.row] capitalizedString];
    
    SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue *)segue;
    swSegue.performBlock = ^(SWRevealViewControllerSegue *rvc_segue, UIViewController *svc, UIViewController *dvc) {
        UINavigationController *navController = (UINavigationController*)self.revealViewController.frontViewController;
        [navController setViewControllers:@[dvc] animated:NO];
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    };
}

@end
