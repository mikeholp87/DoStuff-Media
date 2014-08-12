//
//  JSONReader.m
//  Do512
//
//  Created by Michael Holp on 2/10/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "JSONReader.h"
#import "HTTPClient.h"

@implementation JSONReader
{
    HTTPClient *httpClient;
    NSMutableDictionary *jsonDict;
}

+ (JSONReader *)sharedInstance {
    static JSONReader *sharedInstance = nil;
    if (sharedInstance == nil)
        sharedInstance = [[JSONReader alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if(self) {
        httpClient = [[HTTPClient alloc] init];
        jsonDict = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchJSON:) name:@"DSDownloadDataNotification" object:nil];
    }
    return self;
}

- (void)fetchJSON:(NSNotification *)notification
{
    NSString *s_url;
    if([notification.userInfo[@"type"] isEqualToString:@"events"]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"])
            s_url = [NSString stringWithFormat:@"http://sx2014.do512.com/events.json"];
        else{
            if([notification.userInfo[@"day"] isEqualToString:@"today"]){
                [[NSUserDefaults standardUserDefaults] setObject:[self getDate:[NSDate date]] forKey:@"menuDate"];
                s_url = [NSString stringWithFormat:@"http://do%@.com/events/today.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
            }else if([notification.userInfo[@"day"] isEqualToString:@"tomorrow"]){
                [[NSUserDefaults standardUserDefaults] setObject:[self getDate:[[NSDate date] dateByAddingTimeInterval:86400]] forKey:@"menuDate"];
                s_url = [NSString stringWithFormat:@"http://do%@.com/events/tomorrow.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
            }else if([notification.userInfo[@"day"] isEqualToString:@"weekend"]){
                [[NSUserDefaults standardUserDefaults] setObject:@"Weekend" forKey:@"menuDate"];
                s_url = [NSString stringWithFormat:@"http://do%@.com/events/weekend.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
            }else if([notification.userInfo[@"day"] isEqualToString:@"week"]){
                [[NSUserDefaults standardUserDefaults] setObject:@"Week" forKey:@"menuDate"];
                s_url = [NSString stringWithFormat:@"http://do%@.com/events/week.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
            }else{
                [[NSUserDefaults standardUserDefaults] setObject:@"Month" forKey:@"menuDate"];
                s_url = [NSString stringWithFormat:@"http://do%@.com/events/month.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else if([notification.userInfo[@"type"] isEqualToString:@"latest"]){
        s_url = [NSString stringWithFormat:@"http://do%@.com/latest.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
    }else if ([notification.userInfo[@"type"] isEqualToString:@"giveaways"]){
        if([notification.userInfo[@"mode"] isEqualToString:@"upcoming"])
            s_url = [NSString stringWithFormat:@"http://do%@.com/WinStuff/events.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
        else if([notification.userInfo[@"mode"] isEqualToString:@"past"])
            s_url = [NSString stringWithFormat:@"http://do%@.com/WinStuff/past_events.json?view=%@?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"mode"], notification.userInfo[@"page"]];
        else
            s_url = [NSString stringWithFormat:@"http://do%@.com/WinStuff/artists.json?page=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"], notification.userInfo[@"page"]];
    }else if([notification.userInfo[@"type"] isEqualToString:@"layout"]){
        s_url = [NSString stringWithFormat:@"http://do%@.com/layout.json", [[NSUserDefaults standardUserDefaults] objectForKey:@"areacode"]];
    }else{
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"SX2014"])
            s_url = [NSString stringWithFormat:@"http://sx2014.do512.com/%@.json", notification.userInfo[@"type"]];
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        jsonDict = [httpClient fetchJSON:[NSURL URLWithString:s_url]];
        [self savePlist:jsonDict filename:notification.userInfo[@"type"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DSReloadDataNotification" object:self userInfo:nil];
    }];
}

- (NSString *)getDate:(NSDate *)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMM dd"];
    NSString *dateString = [dateFormat stringFromDate:date];
    
    return [NSString stringWithFormat:@"%@", dateString];
}

- (void)savePlist:(NSMutableDictionary *)dict filename:(NSString *)filename
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    
    [data writeToFile:path atomically:YES];
}

- (NSMutableDictionary *)getPlist:(NSString *)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    return [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
