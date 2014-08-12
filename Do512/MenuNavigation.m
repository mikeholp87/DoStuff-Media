//
//  MenuView.m
//  Do512
//
//  Created by Mike Holp on 5/25/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "MenuNavigation.h"
#import "EventsTable.h"
#import "LatestTable.h"
#import "GiveawayTable.h"

@interface MenuNavigation ()
@property (nonatomic, retain) UIButton *menuBtn0;
@property (nonatomic, retain) UIButton *menuBtn1;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (strong, readwrite, nonatomic) REMenu *menu0;
@property (strong, readwrite, nonatomic) REMenuItem *menuItem0;
@property (strong, readwrite, nonatomic) REMenu *menu1;
@property (strong, readwrite, nonatomic) REMenuItem *menuItem1;
@end

@implementation MenuNavigation

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitle) name:@"DSSelectMenuNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleMenu) name:@"DSToggleMenuNotification" object:nil];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Giveaways"]){
        self.menuBtn0 = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.menuBtn0 setTitle:@"UPCOMING" forState:UIControlStateNormal];
        REMenuItem *upcoming = [[REMenuItem alloc] initWithTitle:@"UPCOMING"
                                                          subtitle:@""
                                                             image:[UIImage imageNamed:@"ds-nav-menu"]
                                                  highlightedImage:nil
                                                            action:^(REMenuItem *item) {
                                                                NSLog(@"Item: %@", item);
                                                                self.menuItem0 = item;
                                                                self.userInfo = @{@"type":@"giveaways", @"mode":@"upcoming"};
                                                                [self sendNotifs];
                                                            }];
        REMenuItem *past = [[REMenuItem alloc] initWithTitle:@"PREVIOUS"
                                                     subtitle:@""
                                                        image:[UIImage imageNamed:@"ds-nav-menu"]
                                             highlightedImage:nil
                                                       action:^(REMenuItem *item) {
                                                           NSLog(@"Item: %@", item);
                                                           self.menuItem0 = item;
                                                           self.userInfo = @{@"type":@"giveaways", @"mode":@"past"};
                                                           [self sendNotifs];
                                                       }];
        
        REMenuItem *artists = [[REMenuItem alloc] initWithTitle:@"ARTISTS"
                                                     subtitle:@""
                                                        image:[UIImage imageNamed:@"ds-nav-menu"]
                                             highlightedImage:nil
                                                       action:^(REMenuItem *item) {
                                                           NSLog(@"Item: %@", item);
                                                           self.menuItem0 = item;
                                                           self.userInfo = @{@"type":@"giveaways", @"mode":@"artists"};
                                                           [self sendNotifs];
                                                       }];
        
        upcoming.tag = 0;
        past.tag = 1;
        artists.tag = 2;
        
        self.menu0 = [[REMenu alloc] initWithItems:@[upcoming, past]];
    }else if([[NSUserDefaults standardUserDefaults] boolForKey:@"Events"]){
        self.menuBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.menuBtn1 setTitle:@"TODAY" forState:UIControlStateNormal];
        REMenuItem *today = [[REMenuItem alloc] initWithTitle:@"TODAY"
                                                     subtitle:@""
                                                        image:[UIImage imageNamed:@"ds-nav-menu"]
                                             highlightedImage:nil
                                                       action:^(REMenuItem *item) {
                                                           NSLog(@"Item: %@", item);
                                                           self.menuItem1 = item;
                                                           self.userInfo = @{@"type":@"events", @"day":@"today"};
                                                           [self sendNotifs];
                                                       }];
        
        REMenuItem *tomorrow = [[REMenuItem alloc] initWithTitle:@"TOMORROW"
                                                        subtitle:@""
                                                           image:[UIImage imageNamed:@"ds-nav-menu"]
                                                highlightedImage:nil
                                                          action:^(REMenuItem *item) {
                                                              NSLog(@"Item: %@", item);
                                                              self.menuItem1 = item;
                                                              self.userInfo = @{@"type":@"events", @"day":@"tomorrow"};
                                                              [self sendNotifs];
                                                          }];
        
        REMenuItem *weekend = [[REMenuItem alloc] initWithTitle:@"WEEKEND"
                                                       subtitle:@""
                                                          image:[UIImage imageNamed:@"ds-nav-menu"]
                                               highlightedImage:nil
                                                         action:^(REMenuItem *item) {
                                                             NSLog(@"Item: %@", item);
                                                             self.menuItem1 = item;
                                                             self.userInfo = @{@"type":@"events", @"day":@"weekend"};
                                                             [self sendNotifs];
                                                         }];
        
        REMenuItem *week = [[REMenuItem alloc] initWithTitle:@"WEEK"
                                                    subtitle:@""
                                                       image:[UIImage imageNamed:@"ds-nav-menu"]
                                            highlightedImage:nil
                                                      action:^(REMenuItem *item) {
                                                          NSLog(@"Item: %@", item);
                                                          self.menuItem1 = item;
                                                          self.userInfo = @{@"type":@"events", @"day":@"week"};
                                                          [self sendNotifs];
                                                      }];
        
        REMenuItem *month = [[REMenuItem alloc] initWithTitle:@"MONTH"
                                                     subtitle:@""
                                                        image:[UIImage imageNamed:@"ds-nav-menu"]
                                             highlightedImage:nil
                                                       action:^(REMenuItem *item) {
                                                           NSLog(@"Item: %@", item);
                                                           self.menuItem1 = item;
                                                           self.userInfo = @{@"type":@"events", @"day":@"month"};
                                                           [self sendNotifs];
                                                       }];
        
        today.tag = 0;
        tomorrow.tag = 1;
        weekend.tag = 2;
        week.tag = 3;
        month.tag = 4;
        
        self.menu1 = [[REMenu alloc] initWithItems:@[today, tomorrow, weekend, week, month]];
    }
    
    self.menuBtn0.frame = CGRectMake(5, 5, 150, 35);
    [self.menuBtn0 setBackgroundImage:[UIImage imageNamed:@"ds-dropdown.png"] forState:UIControlStateNormal];
    [self.menuBtn0 addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.menuBtn0];
    
    self.menuBtn1.frame = CGRectMake(5, 5, 150, 35);
    [self.menuBtn1 setBackgroundImage:[UIImage imageNamed:@"ds-dropdown.png"] forState:UIControlStateNormal];
    [self.menuBtn1 addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.menuBtn1];
    
    self.menu0.backgroundColor = [UIColor colorWithRed:213/255.0 green:65/255.0 blue:67/255.0 alpha:1];
    self.menu0.separatorColor = [UIColor clearColor];
    self.menu0.textColor = [UIColor whiteColor];
    self.menu0.subtitleTextColor = [UIColor whiteColor];
    self.menu0.textAlignment = NSTextAlignmentCenter;
    self.menu0.imageOffset = CGSizeMake(5, -1);
    self.menu0.waitUntilAnimationIsComplete = NO;
    self.menu0.badgeLabelConfigurationBlock = ^(UILabel *badgeLabel, REMenuItem *item) {
        badgeLabel.backgroundColor = [UIColor colorWithRed:0 green:179/255.0 blue:134/255.0 alpha:1];
        badgeLabel.layer.borderColor = [UIColor colorWithRed:0.000 green:0.648 blue:0.507 alpha:1.000].CGColor;
    };
    
    self.menu1.backgroundColor = [UIColor colorWithRed:213/255.0 green:65/255.0 blue:67/255.0 alpha:1];
    self.menu1.separatorColor = [UIColor clearColor];
    self.menu1.textColor = [UIColor whiteColor];
    self.menu1.subtitleTextColor = [UIColor whiteColor];
    self.menu1.textAlignment = NSTextAlignmentCenter;
    self.menu1.imageOffset = CGSizeMake(5, -1);
    self.menu1.waitUntilAnimationIsComplete = NO;
    self.menu1.badgeLabelConfigurationBlock = ^(UILabel *badgeLabel, REMenuItem *item) {
        badgeLabel.backgroundColor = [UIColor colorWithRed:0 green:179/255.0 blue:134/255.0 alpha:1];
        badgeLabel.layer.borderColor = [UIColor colorWithRed:0.000 green:0.648 blue:0.507 alpha:1.000].CGColor;
    };
    
    [self.menu0 setClosePreparationBlock:^{
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"page"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    
    [self.menu1 setClosePreparationBlock:^{
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"page"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
}

- (NSString *)getDate:(NSDate *)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMM dd"];
    NSString *dateString = [dateFormat stringFromDate:date];
    
    return [NSString stringWithFormat:@"%@", dateString];
}

- (void)sendNotifs
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSDownloadDataNotification" object:self userInfo:self.userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSSelectMenuNotification" object:self userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSToggleMenuNotification" object:self userInfo:nil];
}

- (void)updateTitle
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Giveaways"])
        [self.menuBtn0 setTitle:self.menuItem0.title forState:UIControlStateNormal];
    else
        [self.menuBtn1 setTitle:self.menuItem1.title forState:UIControlStateNormal];
}

- (void)toggleMenu
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Giveaways"]){
        if(self.menu0.isOpen){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DSHideMenuNotification" object:self userInfo:nil];
            [self.menu0 close];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DSShowMenuNotification" object:self userInfo:nil];
            [self.menu0 showFromRect:CGRectMake(0, 65, 320, 300) inView:self.view];
        }
    }else{
        if(self.menu1.isOpen){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DSHideMenuNotification" object:self userInfo:nil];
            [self.menu1 close];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DSShowMenuNotification" object:self userInfo:nil];
            [self.menu1 showFromRect:CGRectMake(0, 65, 320, 300) inView:self.view];
        }
    }
}

@end
