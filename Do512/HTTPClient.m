//
//  HTTPClient.m
//  Do512
//
//  Created by Michael Holp on 2/10/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import "HTTPClient.h"

@implementation HTTPClient

- (NSMutableDictionary *)fetchJSON:(NSURL *)url
{
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    
    return jsonDict;
    
    return 0;
}

@end
