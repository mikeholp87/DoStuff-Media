//
//  HTTPClient.h
//  Do512
//
//  Created by Michael Holp on 2/10/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPClient : NSObject

- (NSMutableDictionary *)fetchJSON:(NSURL *)url;

@end
