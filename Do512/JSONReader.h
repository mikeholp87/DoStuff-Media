//
//  JSONReader.h
//  Do512
//
//  Created by Michael Holp on 2/10/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface JSONReader : NSObject

+ (JSONReader *)sharedInstance;
- (NSMutableDictionary *)getPlist:(NSString *)filename;
- (void)fetchJSON:(NSNotification *)notification;

@end
