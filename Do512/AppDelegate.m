//
//  AppDelegate.m
//  Do512
//
//  Created by Michael Holp on 1/17/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "AppDelegate.h"
#import "JSONReader.h"
#import "Flurry.h"
#import <HockeySDK/HockeySDK.h>
#import <Crashlytics/Crashlytics.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"af606f31c5c148f33d94ee0e0795e1b8"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"6NJY6278R4Q95JYBQG3T"];
    
    [JSONReader sharedInstance];
    
    if([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
        self.window.tintColor = [UIColor lightGrayColor];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
